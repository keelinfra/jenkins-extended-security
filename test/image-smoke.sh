#!/usr/bin/env bash
# Check an image built by docker/build.sh behaves like the official jenkins/jenkins image.
#
# Usage: test/image-smoke.sh IMAGE EXPECTED_JENKINS_VERSION
#   PORT  environment variable, default 8090
# Needs: docker, curl, network access to updates.jenkins.io (for jenkins-plugin-cli).
set -euo pipefail

image=$1
expected=$2
port=${PORT:-8090}
fail() { echo "FAIL: $*" >&2; exit 1; }
run() { docker run --rm --entrypoint "$1" "$image" "${@:2}"; }

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

# 3. Starts, and reports the patched version.
cid=$(docker run -d -p "127.0.0.1:$port:8080" -e JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Dhudson.model.UpdateCenter.never=true" "$image")
trap 'docker rm -f "$cid" > /dev/null' EXIT
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
