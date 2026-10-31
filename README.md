<a href="https://keelinfra.io">
  <picture>
    <source media="(prefers-color-scheme: dark)"
            srcset="https://raw.githubusercontent.com/keelinfra/.github/main/assets/wordmark-dark.svg">
    <img alt="keelinfra" width="280"
         src="https://raw.githubusercontent.com/keelinfra/.github/main/assets/wordmark-light.svg">
  </picture>
</a>

# Extended Security for Jenkins

[![CI 2.541.x](https://github.com/keelinfra/jenkins-extended-security/actions/workflows/ci.yml/badge.svg?branch=stable-2.541)](https://github.com/keelinfra/jenkins-extended-security/actions/workflows/ci.yml?query=branch%3Astable-2.541)
[![Lines](https://img.shields.io/badge/lines-2.541.x%20(Java%2017)-blue)](#lines)
[![License: MIT, BSD-2-Clause parts](https://img.shields.io/badge/license-MIT%20%2B%20BSD--2--Clause%20parts-green)](#license)

Jenkins core security fixes, backported to the last LTS line that runs on each Java version, for controllers that can't move to a newer Java yet.

> This is not an official Jenkins release. It is not covered by Jenkins security advisories, CVE assignments or the Jenkins security team. The way off an old line is to [move to a newer Java](https://www.jenkins.io/doc/book/platform-information/upgrade-java-to-21/) and the current LTS; this only covers the time until you can.

## Lines

Each line lives on its own branch, with the patches, a build script and tests. Each release has the WAR, its SBOM and checksums; you can also build the WAR from source with the line's `build.sh` and get the same file.

| Line | Base | Java | Branch | Latest release | Covers advisories up to |
| --- | --- | --- | --- | --- | --- |
| 2.541.x | 2.541.3, the last LTS on Java 17 | 17 | [`stable-2.541`](../../tree/stable-2.541) | [`2.541.3-k2`](../../releases/tag/2.541.3-k2) | 2026-10-28 |

Only Jenkins core, Remoting and Stapler are patched. Plugins are not.

## Advisories

Every Jenkins security advisory since 2.541.3, and what it means on 2.541.x. When Jenkins publishes a new one, it gets a row here, usually the same day.

| Advisory | Core issues | 2.541.x | Fixed plugins that install on 2.541.3 |
| --- | --- | --- | --- |
| [2026-10-28](https://www.jenkins.io/security/advisory/2026-10-28/) | 15 | in [`2.541.3-k2`](../../releases/tag/2.541.3-k2), released 2026-10-29 | none in this advisory |
| [2026-09-16](https://www.jenkins.io/security/advisory/2026-09-16/) | 0 | nothing to patch | 8 of 13; not: bitbucket-push-and-pull-request (2.555.3), coverage (2.555.3), pipeline-groovy-lib (2.555.1), workflow-multibranch (2.555.3), warnings-ng (2.555.3) |
| [2026-09-02](https://www.jenkins.io/security/advisory/2026-09-02/) | 13 | in [`2.541.3-k2`](../../releases/tag/2.541.3-k2) | 13 of 16; not: customizable-header (2.555.3), azure-ad (2.555.3), pipeline-groovy-lib (2.555.1) |
| [2026-08-05](https://www.jenkins.io/security/advisory/2026-08-05/) | 5 | in [`2.541.3-k2`](../../releases/tag/2.541.3-k2) | 5 of 5 |
| [2026-06-24](https://www.jenkins.io/security/advisory/2026-06-24/) | 0 | nothing to patch | 14 of 14 |
| [2026-06-10](https://www.jenkins.io/security/advisory/2026-06-10/) | 7 | in [`2.541.3-k2`](../../releases/tag/2.541.3-k2) | none in this advisory |
| [2026-05-27](https://www.jenkins.io/security/advisory/2026-05-27/) | 0 | nothing to patch | 10 of 10 |
| [2026-04-29](https://www.jenkins.io/security/advisory/2026-04-29/) | 0 | nothing to patch | 7 of 7 |

The 2.541.x line started on 2026-10-27; its first release covered the four earlier advisories with core issues at once. Which upstream commit each core fix comes from is in the line's [COVERAGE.md](../../blob/stable-2.541/COVERAGE.md).

A fixed plugin counts as installing on 2.541.3 when the fixed version, and the minimum version of each dependency it requires, need Jenkins 2.541.3 or older according to the update center (checked 2026-10-31). In brackets is the core a plugin needs instead. This is read from metadata, not tested by starting Jenkins, and plugins the advisory lists without a fix are not counted. [`scripts/advisory.py`](scripts/advisory.py) makes a row: `scripts/advisory.py 2026-09-16`.

## Install

The release WAR replaces the `jenkins.war` of a Jenkins already on the line's base version (2.541.3 for 2.541.x). `JENKINS_HOME`, plugins and jobs stay as they are. Back up `JENKINS_HOME` first, as for any upgrade.

Download and check the WAR:

```sh
curl -fLO https://github.com/keelinfra/jenkins-extended-security/releases/download/2.541.3-k2/jenkins.war
curl -fLO https://github.com/keelinfra/jenkins-extended-security/releases/download/2.541.3-k2/sha256sums.txt
sha256sum -c sha256sums.txt
gh attestation verify jenkins.war --repo keelinfra/jenkins-extended-security
```

| Jenkins installed with | WAR to replace |
| --- | --- |
| Docker image `jenkins/jenkins` | `/usr/share/jenkins/jenkins.war` |
| deb or rpm package | `/usr/share/java/jenkins.war` |
| `java -jar jenkins.war` | the file you start |

### Docker

Build your own image on top of the official one:

```dockerfile
FROM jenkins/jenkins:2.541.3-lts-jdk17
COPY --chown=root:root jenkins.war /usr/share/jenkins/jenkins.war
```

Only the WAR changes. The JDK and OS packages in that base image are the ones it was built with in March 2026, so keep them patched yourself.

### deb or rpm

```sh
sudo systemctl stop jenkins
sudo cp /usr/share/java/jenkins.war /usr/share/java/jenkins.war.2.541.3
sudo install -m 0644 -o root -g root jenkins.war /usr/share/java/jenkins.war
sudo apt-mark hold jenkins          # rpm: sudo dnf versionlock add jenkins
sudo systemctl start jenkins
```

Hold the package, or the next package upgrade puts back an upstream WAR.

### Check it

The `X-Jenkins` header and the version in the page footer show the patched version:

```sh
curl -sI http://localhost:8080/login | grep X-Jenkins    # X-Jenkins: 2.541.3-k2
```

Jenkins will still say a newer version is available. If Manage Jenkins offers to upgrade automatically, don't: that downloads the upstream WAR, which needs Java 21.

To roll back, put the stock 2.541.3 WAR back and restart.

## Security

See [SECURITY.md](SECURITY.md).

## License

This repository's own files are MIT, see [LICENSE](LICENSE). The patches keep the license of the project they come from: MIT for Jenkins and Remoting, BSD 2-Clause for Stapler. Each line's branch has the full texts in `LICENSES/`.
