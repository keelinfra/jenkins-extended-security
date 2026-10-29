<a href="https://keelinfra.io">
  <picture>
    <source media="(prefers-color-scheme: dark)"
            srcset="https://raw.githubusercontent.com/keelinfra/.github/main/assets/wordmark-dark.svg">
    <img alt="keelinfra" width="280"
         src="https://raw.githubusercontent.com/keelinfra/.github/main/assets/wordmark-light.svg">
  </picture>
</a>

# Extended Security for Jenkins 2.541.x

[![CI](https://github.com/keelinfra/jenkins-extended-security/actions/workflows/ci.yml/badge.svg?branch=stable-2.541)](https://github.com/keelinfra/jenkins-extended-security/actions/workflows/ci.yml?query=branch%3Astable-2.541)
[![Base](https://img.shields.io/badge/base-Jenkins%202.541.3-blue)](#whats-in-it)
[![Controller Java](https://img.shields.io/badge/controller%20Java-17%20%7C%2021-blue)](#test)
[![Advisories](https://img.shields.io/badge/advisories-up%20to%202026--10--28-blue)](COVERAGE.md)
[![License: MIT, BSD-2-Clause parts](https://img.shields.io/badge/license-MIT%20%2B%20BSD--2--Clause%20parts-green)](#license)

Patches that apply the core security fixes released after Jenkins 2.541.3 to 2.541.3, the last LTS that runs on Java 17, plus a script to build the WAR from them.

> This is not an official Jenkins release. It is not covered by Jenkins security advisories, CVE assignments or the Jenkins security team. The way off 2.541.x is to [move to Java 21](https://www.jenkins.io/doc/book/platform-information/upgrade-java-to-21/) and the current LTS; this only covers the time until you can.

This is the 2.541.x line. The [main branch](../../tree/main) lists all lines.

## What's in it

- [`patches/jenkins`](patches/jenkins): 49 patches on tag `jenkins-2.541.3`. 0001 to 0030 and 0032 to 0049 are security fixes and their adaptations; `0031` is a test-only backport that makes `QueueTest` stable in CI.
- [`patches/remoting`](patches/remoting): 1 patch on Remoting `3352.v17a_fb_4b_2773f`, the version 2.541.3 ships.
- [`patches/stapler`](patches/stapler): 5 patches on Stapler `2050.v425108fd5089`, the version 2.541.3 ships. Four are security fixes; `0005` is a build fix that makes the WAR reproducible (see below).

They cover the 40 core issues from the 2026-06-10, 2026-08-05, 2026-09-02 and 2026-10-28 advisories. [COVERAGE.md](COVERAGE.md) lists each issue, its upstream commit, and where the backport differs from upstream.

Plugins are not patched. Update them as usual: most plugin security fixes since 2.541.3 still install on it, but a growing number need a newer core.

## Versions

Patched builds never reuse an upstream version, so a build can't pull unpatched artifacts back in, and scanners and bug reports can tell them apart from stock 2.541.3:

| Component | Version |
| --- | --- |
| Jenkins WAR | `2.541.3-k2` |
| Remoting | `3352.k2541.1` |
| Stapler | `2050.k2541.1` |

## Download

Each [release](../../releases) has `jenkins.war`, its CycloneDX SBOM, `sha256sums.txt` and `build-info.txt`. Check the WAR before you use it:

```sh
sha256sum -c sha256sums.txt
gh attestation verify jenkins.war --repo keelinfra/jenkins-extended-security
```

Or build it yourself (below): the same commit, with the JDK and Maven listed in `build-info.txt`, gives the same WAR.

## Build

Needs git, JDK 17 or 21, Maven 3.9+ and access to github.com and repo.jenkins-ci.org. Tested with OpenJDK 21.0.12 and Maven 3.9.11.

```sh
./build.sh    # output: work/jenkins.war, work/sha256sums.txt, work/build-info.txt
```

`build.sh` clones the three upstream tags, applies the patches with `git am`, builds and installs Remoting and Stapler under the versions above, then builds the WAR against them. The build is reproducible: the same patches and tool versions give a byte-identical WAR, so anyone can rebuild it and compare `sha256sums.txt`. Getting there took two changes. `build.sh` applies the patches with fixed committer dates, because the WAR records the commit id. And Stapler patch `0005` fixes its annotation processor, which skipped some `.stapler` files depending on HashSet order (upstream Stapler still has this; it has no effect at runtime because Jenkins reads parameter names via reflection).

## Test

| Script | What it checks | Time |
| --- | --- | --- |
| `test/run-tests.sh` | The unit and integration tests the backported fixes add or change, including the new security tests | 15-20 min |
| `test/plugin-boot.sh work/jenkins.war` | Boots the WAR with the 100 most popular plugins (`test/plugins-top300.txt` for 300) and runs a Pipeline on an inbound WebSocket agent | 2-5 min |
| `test/war-diff.sh stock.war work/jenkins.war` | The WAR has the same files as stock 2.541.3, apart from versioned jar names and the signature | seconds |

Run `plugin-boot.sh` on the [stock 2.541.3 WAR](https://get.jenkins.io/war-stable/2.541.3/jenkins.war) as well; the two results should match.

The full upstream test suite and the Acceptance Test Harness are not run yet.

## CI

Every push and pull request to a `stable-*` branch runs [CI](.github/workflows/ci.yml):

- `shellcheck` on the scripts.
- The build on JDK 21, plus a CycloneDX SBOM of the WAR made with [Syft](https://github.com/anchore/syft). The SBOM covers everything inside the WAR, including Jetty and the bundled detached plugins.
- A second build on a fresh runner without the Maven cache. Its sha256 must match the first.
- `test/run-tests.sh` on JDK 17 and 21.
- `test/war-diff.sh` and `test/plugin-boot.sh`, on the stock 2.541.3 WAR and on ours, with Java 17 and 21 as the controller JVM. Both must get the same plugin versions.

Builds from pushes get [build provenance and SBOM attestations](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations). The WAR stays a workflow artifact for 30 days so you can compare it with your own build. It is not a release. To check a WAR from CI:

```sh
gh attestation verify jenkins.war --repo keelinfra/jenkins-extended-security
```

## Release

Releases are made by hand with [`release.yml`](.github/workflows/release.yml) (Actions → Release → Run workflow on a `stable-*` branch). It refuses a commit without a green CI run, rebuilds the WAR on a fresh runner and checks it is byte-identical to the CI build, attests provenance and the SBOM, and creates a draft release for review. The CI build it compares against is kept for 30 days; after that, run CI again by hand first.

## Security

See [SECURITY.md](SECURITY.md) for where to report problems.

## License

The patches keep the license of the project they come from, with that project's copyright notice:

| Patches | License |
| --- | --- |
| `patches/jenkins` | MIT, [LICENSES/jenkins-MIT.txt](LICENSES/jenkins-MIT.txt) |
| `patches/remoting` | MIT, [LICENSES/remoting-MIT.md](LICENSES/remoting-MIT.md) and [NOTICE](LICENSES/remoting-NOTICE) |
| `patches/stapler` | BSD 2-Clause, [LICENSES/stapler-BSD-2-Clause.txt](LICENSES/stapler-BSD-2-Clause.txt) |

Everything else (scripts, tests, workflows, docs) is MIT, see [LICENSE](LICENSE).
