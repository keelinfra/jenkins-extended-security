#!/usr/bin/env bash
# Run the tests the backported fixes touch, on a tree prepared by ../build.sh.
#
# Usage: test/run-tests.sh [WORKDIR]      (default: ./work)
# Runs core unit tests (core-tests.txt) and JenkinsRule integration tests
# (integration-tests.txt). The integration tests take about 15-20 minutes.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
work=$(cd "${1:-$here/../work}" && pwd)
mvn_opts=(-B -ntp -Dchangelist=-k1 -Dspotbugs.skip -Dspotless.check.skip=true -Denforcer.skip
          -Dlicense.skip=true -Dcheckstyle.skip -Dsurefire.failIfNoSpecifiedTests=false)

list() { paste -sd, "$here/$1"; }

cd "$work/jenkins"
mvn "${mvn_opts[@]}" -pl core test -Dtest="$(list core-tests.txt)"
mvn "${mvn_opts[@]}" -pl test test -Dtest="$(list integration-tests.txt)"
