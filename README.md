# Extended Security for Jenkins 2.541.x

Patches that apply the core security fixes released after Jenkins 2.541.3 to 2.541.3, the last LTS that runs on Java 17, plus a script to build the WAR from them.

> This is not an official Jenkins release. It is not covered by Jenkins security advisories, CVE assignments or the Jenkins security team. The way off 2.541.x is to [move to Java 21](https://www.jenkins.io/doc/book/platform-information/upgrade-java-guidelines/) and the current LTS; this only covers the time until you can.

This is the 2.541.x line. The [main branch](../../tree/main) lists all lines.

## What's in it

- [`patches/jenkins`](patches/jenkins): 30 patches on tag `jenkins-2.541.3`.
- [`patches/remoting`](patches/remoting): 1 patch on Remoting `3352.v17a_fb_4b_2773f`, the version 2.541.3 ships.
- [`patches/stapler`](patches/stapler): 5 patches on Stapler `2050.v425108fd5089`, the version 2.541.3 ships. Four are security fixes; `0005` is a build fix that makes the WAR reproducible (see below).

They cover the 25 core issues from the 2026-06-10, 2026-08-05 and 2026-09-02 advisories. [COVERAGE.md](COVERAGE.md) lists each issue, its upstream commit, and where the backport differs from upstream.

Plugins are not patched. Update them as usual: most plugin security fixes since 2.541.3 still install on it, but a growing number need a newer core.

## Versions

Patched builds never reuse an upstream version, so a build can't pull unpatched artifacts back in, and scanners and bug reports can tell them apart from stock 2.541.3:

| Component | Version |
| --- | --- |
| Jenkins WAR | `2.541.3-k1` |
| Remoting | `3352.k2541.1` |
| Stapler | `2050.k2541.1` |

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

## Security

See [SECURITY.md](SECURITY.md) for where to report problems.

## License

The patches are taken from Jenkins, Remoting and Stapler, which are MIT-licensed. The scripts in this repository are MIT-licensed too.
