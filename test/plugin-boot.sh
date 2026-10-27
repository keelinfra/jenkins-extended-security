#!/usr/bin/env bash
# Boot a Jenkins WAR with popular plugins and run one Pipeline on an inbound agent.
#
# Usage: test/plugin-boot.sh WAR [PLUGIN_LIST] [WORKDIR]
#   PLUGIN_LIST  default: test/plugins-top100.txt (test/plugins-top300.txt for the bigger set)
#   WORKDIR      default: ./work/plugin-boot-<name of the WAR file>
#   PORT         environment variable, default 8089
#   PLUGIN_CACHE environment variable, a directory to download plugins into and reuse
#                between runs (use one per plugin list)
#
# Run it on the stock 2.541.3 WAR and on the patched one. Both get the same plugin
# versions (the newest that support 2.541.3), so the results should match.
# Needs: JDK 17 or 21, curl, unzip, network access to github.com and updates.jenkins.io.
set -euo pipefail

PIM_VERSION=2.15.0
PIM_SHA256=a86853ec2e2933f37a4b471ba65099b61e03c87a80c2ef8fe2315eb135672d43

here=$(cd "$(dirname "$0")" && pwd)
war=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
list=${2:-$here/plugins-top100.txt}
work=${3:-$here/../work/plugin-boot-$(basename "$war" .war)}
port=${PORT:-8089}
url=http://127.0.0.1:$port

mkdir -p "$work"; work=$(cd "$work" && pwd)
home=$work/home
rm -rf "$home" "$work/agent"; mkdir -p "$home/init.groovy.d" "$work/agent"

# 1. Plugin installation manager, the tool the official Docker image uses.
pim=$work/jenkins-plugin-manager-$PIM_VERSION.jar
if [ ! -f "$pim" ]; then
  curl -fsSL -o "$pim" "https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/$PIM_VERSION/jenkins-plugin-manager-$PIM_VERSION.jar"
fi
echo "$PIM_SHA256  $pim" | sha256sum -c --quiet

# 2. Resolve and download plugins for 2.541.3 (pinned, so the -k1 suffix can't change the result).
# The update center mirrors sometimes drop connections, so retry. Plugins already in
# $cache are kept, so a second run with the same PLUGIN_CACHE downloads nothing.
cache=${PLUGIN_CACHE:-$work/plugin-download}
mkdir -p "$cache"
for attempt in 1 2 3; do
  if java -jar "$pim" --war "$war" --jenkins-version 2.541.3 --plugin-file "$list" \
       --plugin-download-directory "$cache" > "$work/plugins.log" 2>&1; then
    break
  fi
  if [ "$attempt" = 3 ]; then tail -20 "$work/plugins.log" >&2; exit 1; fi
  echo "plugin download failed (attempt $attempt), retrying" >&2
  sleep 15
done
mkdir -p "$home/plugins"
cp "$cache"/*.jpi "$home/plugins/"

for f in "$home"/plugins/*.jpi; do
  printf '%s %s\n' "$(basename "$f" .jpi)" \
    "$(unzip -p "$f" META-INF/MANIFEST.MF | sed -n 's/^Plugin-Version: //p' | tr -d '\r')"
done > "$work/plugin-versions.txt"

# 3. On startup, add an inbound agent and a Pipeline that runs on it.
cat > "$home/init.groovy.d/smoke.groovy" <<'GROOVY'
import hudson.slaves.DumbSlave
import hudson.slaves.JNLPLauncher
import jenkins.model.Jenkins
import org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition
import org.jenkinsci.plugins.workflow.job.WorkflowJob

def j = Jenkins.get()
def agent = new DumbSlave('agent1', System.getenv('SMOKE_AGENT_DIR'), new JNLPLauncher())
agent.numExecutors = 1
agent.labelString = 'agent1'
j.addNode(agent)
new File(j.rootDir, 'agent1.secret').text = j.getComputer('agent1').jnlpMac
def job = j.createProject(WorkflowJob, 'smoke')
job.definition = new CpsFlowDefinition('''
node('agent1') {
  sh 'echo hello-from-agent && java -version'
  writeFile file: 'a.txt', text: 'x'
  archiveArtifacts 'a.txt'
}''', true)
job.scheduleBuild2(0)
GROOVY

log=$work/jenkins.log
JENKINS_HOME=$home SMOKE_AGENT_DIR=$work/agent java -Djenkins.install.runSetupWizard=false \
  -Dhudson.model.UpdateCenter.never=true -jar "$war" --httpPort="$port" --httpListenAddress=127.0.0.1 > "$log" 2>&1 &
jpid=$!
apid=
cleanup() { [ -n "$apid" ] && kill "$apid" 2>/dev/null; kill "$jpid" 2>/dev/null; wait 2>/dev/null || true; }
trap cleanup EXIT

start=$(date +%s); up=no
for _ in $(seq 300); do
  if grep -q 'Jenkins is fully up and running' "$log"; then up=yes; break; fi
  kill -0 "$jpid" 2>/dev/null || break
  sleep 2
done
secs=$(( $(date +%s) - start ))
login=$(curl -s -o /dev/null -w '%{http_code}' "$url/login" || true)

# 4. Connect the agent over WebSocket and wait for the build.
result=none
if [ "$up" = yes ]; then
  curl -fsS -o "$work/agent.jar" "$url/jnlpJars/agent.jar"
  java -jar "$work/agent.jar" -url "$url/" -name agent1 -secret "$(cat "$home/agent1.secret")" \
    -workDir "$work/agent" -webSocket > "$work/agent.log" 2>&1 &
  apid=$!
  for _ in $(seq 90); do
    result=$(curl -s "$url/job/smoke/1/api/json?tree=result" | sed -n 's/.*"result":"\([A-Z]*\)".*/\1/p')
    [ -n "$result" ] && break
    result=none; sleep 2
  done
  curl -s "$url/job/smoke/1/consoleText" > "$work/smoke-console.txt" || true
fi

plugins=$(find "$home/plugins" -name '*.jpi' | wc -l)
failed=$(grep -c 'Failed Loading plugin' "$log" || true)
severe=$(grep -c 'SEVERE' "$log" || true)
echo "war=$(basename "$war") plugins=$plugins up=$up secs=$secs login=$login failedLoading=$failed severe=$severe pipeline=$result"
echo "logs: $work"
[ "$up" = yes ] && [ "$login" = 200 ] && [ "$failed" = 0 ] && [ "$result" = SUCCESS ]
