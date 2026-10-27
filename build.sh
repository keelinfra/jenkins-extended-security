#!/usr/bin/env bash
# Build Jenkins 2.541.3 with the security backports in patches/.
#
# Usage: ./build.sh [WORKDIR]      (default: ./work)
# Needs: git, JDK 17 or 21, Maven 3.9+, network access to github.com and repo.jenkins-ci.org.
# Output: WORKDIR/jenkins.war, WORKDIR/sha256sums.txt and WORKDIR/build-info.txt
set -euo pipefail

JENKINS_TAG=jenkins-2.541.3
REMOTING_TAG=3352.v17a_fb_4b_2773f   # the Remoting 2.541.3 ships
STAPLER_TAG=2050.v425108fd5089       # the Stapler 2.541.3 ships

# Version suffixes. Patched Remoting and Stapler get their own versions so a build
# never resolves the unpatched upstream artifacts. The WAR version differs from
# stock 2.541.3 so scanners and bug reports can tell the two apart.
REMOTING_VERSION=3352.k2541.1
STAPLER_VERSION=2050.k2541.1
JENKINS_SUFFIX=-k1                   # WAR version becomes 2.541.3-k1

here=$(cd "$(dirname "$0")" && pwd)
work=$(mkdir -p "${1:-$here/work}" && cd "${1:-$here/work}" && pwd)
mvn_opts=(-B -ntp -DskipTests -Dspotbugs.skip -Dspotless.check.skip=true -Denforcer.skip -Dlicense.skip=true)

checkout() { # repo tag dir patches
  rm -rf "$work/$3"
  git -c advice.detachedHead=false clone -q --depth 1 --branch "$2" "https://github.com/$1.git" "$work/$3"
  # Fixed committer and dates give the same commit ids on every machine. The WAR records
  # the commit id (Implementation-Build), so this keeps the build reproducible.
  git -C "$work/$3" -c user.name=build -c user.email=build@localhost -c commit.gpgsign=false \
    am -q --committer-date-is-author-date "$here/patches/$4"/*.patch
  echo "$3: $2 + $(ls "$here/patches/$4"/*.patch | wc -l) patches"
}

checkout jenkinsci/remoting "$REMOTING_TAG" remoting remoting
checkout jenkinsci/stapler  "$STAPLER_TAG"  stapler  stapler
checkout jenkinsci/jenkins  "$JENKINS_TAG"  jenkins  jenkins

# Patch 0025 and 0026 point core at these versions; fail early if they drift.
grep -q "<remoting.version>$REMOTING_VERSION<" "$work/jenkins/pom.xml" \
  || { echo "jenkins/pom.xml does not use Remoting $REMOTING_VERSION" >&2; exit 1; }
grep -q "<stapler.version>$STAPLER_VERSION<" "$work/jenkins/bom/pom.xml" \
  || { echo "jenkins/bom/pom.xml does not use Stapler $STAPLER_VERSION" >&2; exit 1; }

# Jenkins core pins jar timestamps in its pom; Remoting and Stapler don't, so pin them to
# the date of their last patch.
stamp() { git -C "$work/$1" log -1 --format=%cI; }
(cd "$work/remoting" && mvn "${mvn_opts[@]}" -Dchangelist="$REMOTING_VERSION" \
  -Dproject.build.outputTimestamp="$(stamp remoting)" install)
(cd "$work/stapler"  && mvn "${mvn_opts[@]}" -Dchangelist="$STAPLER_VERSION" \
  -Dproject.build.outputTimestamp="$(stamp stapler)" install)
(cd "$work/jenkins"  && mvn "${mvn_opts[@]}" -Dchangelist="$JENKINS_SUFFIX" -pl war -am install)

cp "$work/jenkins/war/target/jenkins.war" "$work/jenkins.war"
(cd "$work" && sha256sum jenkins.war > sha256sums.txt && cat sha256sums.txt)
{ # what this WAR was built from and with
  echo "jenkins: $JENKINS_TAG + $(ls "$here/patches/jenkins"/*.patch | wc -l) patches"
  echo "remoting: $REMOTING_TAG -> $REMOTING_VERSION"
  echo "stapler: $STAPLER_TAG -> $STAPLER_VERSION"
  echo "patches: $(git -C "$here" rev-parse HEAD 2>/dev/null || echo unknown)"
  java -version 2>&1 | grep -v JAVA_TOOL_OPTIONS | head -1
  mvn -v 2>/dev/null | head -1
} > "$work/build-info.txt"
unzip -p "$work/jenkins.war" META-INF/MANIFEST.MF | grep -E '^Jenkins-Version'
