#!/usr/bin/env bash
# Compare the file list of the patched WAR with the stock 2.541.3 WAR.
#
# Usage: test/war-diff.sh STOCK_WAR PATCHED_WAR
#   STOCK_WAR: https://get.jenkins.io/war-stable/2.541.3/jenkins.war
#
# Expected differences, and nothing else: the stock WAR's JENKINS.SF/JENKINS.RSA
# signature, and the version in the names of the core, CLI, websocket, Remoting
# and Stapler jars. Any other line means a dependency changed.
set -euo pipefail
norm() {
  unzip -Z1 "$1" | sed -E \
    -e 's/-2\.541\.3(-k[0-9]+)?\.jar$/-VERSION.jar/' \
    -e 's/^(WEB-INF\/lib\/remoting)-.*\.jar$/\1-VERSION.jar/' \
    -e 's/^(WEB-INF\/lib\/stapler(-groovy|-jelly)?)-2050\..*\.jar$/\1-VERSION.jar/' \
    -e '/^META-INF\/JENKINS\.(SF|RSA)$/d' | sort
}
if diff <(norm "$1") <(norm "$2"); then
  echo "same files apart from versioned jar names and the stock WAR's signature"
fi
