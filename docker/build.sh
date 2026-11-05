#!/usr/bin/env bash
# Prepare the Docker build context for the patched WAR: the official Jenkins image's
# Dockerfile (jenkinsci/docker, Debian variant) at the 2.541.3 tag, with the patches in
# docker/patches, on the current Debian 13 and Temurin 17.
#
# Usage: docker/build.sh WAR [WORKDIR]      (default WORKDIR: ./work/docker)
#   DEBIAN_VERSION  environment variable, the debian:trixie-<DEBIAN_VERSION>-slim tag;
#                   default: the newest one on Docker Hub
#   JAVA_VERSION    environment variable, e.g. 17.0.21_9; default: the newest Temurin 17
# Output: WORKDIR/context (pass to docker build with -f WORKDIR/context/debian/Dockerfile)
#         and WORKDIR/build-args, one --build-arg per line.
# Needs: git, curl, jq, unzip.
set -euo pipefail

UPSTREAM_REPO=https://github.com/jenkinsci/docker.git
UPSTREAM_TAG=2.541.3
UPSTREAM_COMMIT=cd0890e04944be2ad2a03d433d204f8ef888552d
# Tools the image ships, as in jenkinsci/docker master on 2026-11-03.
GIT_LFS_VERSION=3.8.1
PLUGIN_CLI_VERSION=2.16.0

here=$(cd "$(dirname "$0")" && pwd)
war=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
work=$(mkdir -p "${2:-$here/../work/docker}" && cd "${2:-$here/../work/docker}" && pwd)
ctx=$work/context

if [ -z "${DEBIAN_VERSION:-}" ]; then
  DEBIAN_VERSION=$(curl -fsSL "https://hub.docker.com/v2/repositories/library/debian/tags?name=trixie-20&page_size=100" \
    | jq -r '.results[].name' | sed -n 's/^trixie-\([0-9]\{8\}\)-slim$/\1/p' | sort | tail -1)
fi
if [ -z "${JAVA_VERSION:-}" ]; then
  JAVA_VERSION=$(curl -fsSL "https://api.adoptium.net/v3/info/release_versions?release_type=ga&version=%5B17,18)&page_size=1&sort_order=DESC&vendor=eclipse" \
    | jq -r '.versions[0].semver' | tr + _)
fi
case "$DEBIAN_VERSION" in [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]) ;; *) echo "bad DEBIAN_VERSION '$DEBIAN_VERSION'" >&2; exit 1 ;; esac
case "$JAVA_VERSION" in 17.0.*_*) ;; *) echo "bad JAVA_VERSION '$JAVA_VERSION'" >&2; exit 1 ;; esac

rm -rf "$ctx"
git -c advice.detachedHead=false clone -q --depth 1 --branch "$UPSTREAM_TAG" "$UPSTREAM_REPO" "$ctx"
[ "$(git -C "$ctx" rev-parse HEAD)" = "$UPSTREAM_COMMIT" ] \
  || { echo "jenkinsci/docker tag $UPSTREAM_TAG moved" >&2; exit 1; }
git -C "$ctx" apply "$here"/patches/*.patch
cp "$war" "$ctx/jenkins.war"

version=$(unzip -p "$war" META-INF/MANIFEST.MF | tr -d '\r' | sed -n 's/^Jenkins-Version: //p')
sha=$(sha256sum "$war" | cut -d' ' -f1)
cat > "$work/build-args" <<ARGS
DEBIAN_VERSION=$DEBIAN_VERSION
JAVA_VERSION=$JAVA_VERSION
GIT_LFS_VERSION=$GIT_LFS_VERSION
PLUGIN_CLI_VERSION=$PLUGIN_CLI_VERSION
JENKINS_VERSION=$version
WAR_SHA256=$sha
COMMIT_SHA=$(git -C "$here" rev-parse HEAD 2>/dev/null || echo unknown)
ARGS
cat "$work/build-args"
