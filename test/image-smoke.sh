#!/usr/bin/env bash
# Check an image built by docker/build.sh behaves like the official jenkins/jenkins image.
#
# Usage: test/image-smoke.sh IMAGE EXPECTED_JENKINS_VERSION
#   PORT  environment variable, default 8090
# Needs: docker, curl, unzip, network access to updates.jenkins.io (jenkins-plugin-cli, plugin downloads).
set -euo pipefail

image=$1
expected=$2
port=${PORT:-8090}
fail() { echo "FAIL: $*" >&2; exit 1; }
run() { docker run --rm --entrypoint "$1" "$image" "${@:2}"; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# 1. Same layout and user as the official image.
[ "$(run id -u)" = 1000 ] || fail "not running as uid 1000"
for f in /usr/share/jenkins/jenkins.war /usr/local/bin/jenkins.sh /usr/local/bin/jenkins-support \
         /bin/jenkins-plugin-cli /opt/jenkins-plugin-manager.jar /usr/bin/tini /usr/share/jenkins/ref; do
  run test -e "$f" || fail "missing $f"
done
[ "$(docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "$image" | sed -n 's/^JENKINS_HOME=//p')" = /var/jenkins_home ] \
  || fail "JENKINS_HOME is not /var/jenkins_home"
java_version=$(run java -version 2>&1)
echo "${java_version%%$'\n'*}"

# 2. jenkins-plugin-cli reads the -kN version from the WAR and still resolves plugins,
#    the way a Dockerfile FROM this image would use it.
run jenkins-plugin-cli --plugins git workflow-aggregator --plugin-download-directory /tmp/p > /dev/null \
  || fail "jenkins-plugin-cli could not resolve plugins"

# 3. copy_reference_file() upgrades plugins whose versions the stock 2.541.3 script ordered
#    wrongly (docker/patches/0002). First the comparison, then a real copy onto an existing
#    JENKINS_HOME, the way an image FROM this one with a plugins.txt starts on an old volume.
cases='
1.0 1.1 0
1.1 1.0 1
1.0 1.0 1
3.12.0.0 3.12.0-36.vd97de6465d5b_ 0
1.0.9.0 1.0.9-28.vf251ce40855d 0
3894.vd0f0248b_a_fc4 3894.3896.vca_2c931e7935 0
3894.3896.vca_2c931e7935 3894.vd0f0248b_a_fc4 1
4106.4108.v841a_e1819d4d 4151.v5406e29e3c90 0
1571.vb_423c255d6d9 1571.1585.v21fce07cd04d 0
1571.1585.v21fce07cd04d 1571.vb_423c255d6d9 1
2.84.v72119de229b_7 2.84.86.vf9c960e9b_458 0
2.84.86.vf9c960e9b_458 2.84.v72119de229b_7 1
0.3.0-4.v84c6f0f4969e 0.3.0.1-29.v67e9a_1c969b_b_ 0
0.3.0.1-29.v67e9a_1c969b_b_ 0.3.0-4.v84c6f0f4969e 1
5.6-193.vf028a_770a_fa_c 5.6.3-202.v310919c85b_f6 0
2.30.1.85-299.v15f4832d1275 2.30.1.85.2-304.v4b_5b_62e59a_a_7 0
'
docker run --rm -i --entrypoint bash "$image" -c '. /usr/local/bin/jenkins-support
  while read -r a b want; do
    [ -z "$a" ] && continue
    if versionLT "$a" "$b"; then got=0; else got=1; fi
    [ "$got" = "$want" ] || echo "versionLT $a $b returned $got, expected $want"
  done' <<< "$cases" > "$tmp/versionlt" 2>&1
[ ! -s "$tmp/versionlt" ] || { cat "$tmp/versionlt"; fail "versionLT orders plugin versions wrongly"; }

# eddsa-api: the volume has 0.3.0-4, the image 0.3.0.1-29 (stock 2.541.3 skips this upgrade).
uc=https://updates.jenkins.io/download/plugins/eddsa-api
mkdir -p "$tmp/home/plugins" "$tmp/ref/plugins"
curl -fsSL -o "$tmp/home/plugins/eddsa-api.jpi" "$uc/0.3.0-4.v84c6f0f4969e/eddsa-api.hpi"
echo 0.3.0-4.v84c6f0f4969e > "$tmp/home/plugins/eddsa-api.jpi.version_from_image"
curl -fsSL -o "$tmp/ref/plugins/eddsa-api.jpi" "$uc/0.3.0.1-29.v67e9a_1c969b_b_/eddsa-api.hpi"
docker run --rm --user "$(id -u):$(id -g)" -v "$tmp/home:/var/jenkins_home" -v "$tmp/ref:/usr/share/jenkins/ref:ro" \
  --entrypoint bash "$image" -c '. /usr/local/bin/jenkins-support
    COPY_REFERENCE_FILE_LOG=/var/jenkins_home/copy_reference_file.log
    copy_reference_file /usr/share/jenkins/ref/plugins/eddsa-api.jpi'
got=$(unzip -p "$tmp/home/plugins/eddsa-api.jpi" META-INF/MANIFEST.MF | tr -d '\r' | sed -n 's/^Plugin-Version: //p')
[ "$got" = 0.3.0.1-29.v67e9a_1c969b_b_ ] || { cat "$tmp/home/copy_reference_file.log"; fail "eddsa-api not upgraded on an existing JENKINS_HOME (has $got)"; }

# 4. Starts, and reports the patched version.
cid=$(docker run -d -p "127.0.0.1:$port:8080" -e JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Dhudson.model.UpdateCenter.never=true" "$image")
trap 'docker rm -f "$cid" > /dev/null; rm -rf "$tmp"' EXIT
for _ in $(seq 120); do
  # grep reads from a variable, not a pipe: grep -q on a pipe can end it early (SIGPIPE),
  # which fails the pipeline under pipefail.
  log=$(docker logs "$cid" 2>&1)
  grep -q 'Jenkins is fully up and running' <<< "$log" && break
  [ "$(docker inspect -f '{{.State.Running}}' "$cid")" = true ] || { docker logs "$cid"; fail "container exited"; }
  sleep 2
done
version=$(curl -fsS -o /dev/null -D - "http://127.0.0.1:$port/login" | tr -d '\r' | sed -n 's/^[Xx]-[Jj]enkins: //p')
[ "$version" = "$expected" ] || fail "X-Jenkins is '$version', expected '$expected'"
log=$(docker logs "$cid" 2>&1)
grep -q 'Jenkins is fully up and running' <<< "$log" || { echo "$log"; fail "Jenkins did not start"; }
if grep -q SEVERE <<< "$log"; then grep SEVERE <<< "$log"; fail "SEVERE in the log"; fi
echo "image=$image version=$version ok"
