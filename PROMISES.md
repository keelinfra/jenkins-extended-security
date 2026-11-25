# Promises

What this project promises for each line in the [README](README.md#lines), and what it does not do. Written 2026-11-15. On 2027-11-15 every row gets checked against what actually happened, in a new column in this file. Rows that were not kept stay in the table and say so.

## What we promise

| Promise | How to check |
| --- | --- |
| **Security fixes.** The core, Remoting and Stapler fixes from each Jenkins security advisory published after the line's base version are backported. Each fix is listed in the line's COVERAGE.md with its upstream commit and any change from upstream. | COVERAGE.md on the line's branch ([2.541.x](../../blob/stable-2.541/COVERAGE.md)) |
| **Release timing.** A release within 7 days of a Jenkins security advisory that fixes core, Remoting or Stapler. A dependency update for a known vulnerability, such as Jetty, is released within 30 days. These are targets, not an SLA. | Release dates on the [Releases](../../releases) page against the advisory dates in COVERAGE.md |
| **Security changes only.** Every change is a security fix, a smaller change that a fix needs, a dependency update for a known vulnerability, or a fix to the build, tests or image. Patches that are not security fixes are listed separately in COVERAGE.md. | COVERAGE.md, "Patches that are not security fixes" |
| **Builds you can check.** Each release has the WAR, `sha256sums.txt`, a CycloneDX SBOM, and provenance and SBOM attestations signed through GitHub (Sigstore). A release is only made from a commit CI passed, and only if its WAR is byte-identical to the one CI built. `build.sh` on that commit gives the same file. | `gh attestation verify jenkins.war --repo keelinfra/jenkins-extended-security` |
| **A current Docker image.** `ghcr.io/keelinfra/jenkins` is published within a day of each release. Debian 13 and Temurin are checked every day, and the image is rebuilt when either has an update. Each image has provenance and SBOM attestations; the SBOM is of the amd64 image. | `gh attestation verify oci://ghcr.io/keelinfra/jenkins:2.541 --repo keelinfra/jenkins-extended-security` |
| **Private reporting.** A problem the patches cause can be reported privately. | [SECURITY.md](SECURITY.md) |

## Record

Each release measured against the release-timing promise. Days are calendar days from the trigger to the published release: for a Jenkins advisory, its publication date; for a dependency, the day the vulnerable version was found in the line. Newest first; every later release adds a row, including late ones.

| Trigger date | Trigger | Release | Published | Days | Target |
| --- | --- | --- | --- | --- | --- |
| 2026-11-18 | handlebars, lodash and Guava advisories found in the 2.541.3 WAR ([Other dependencies](../../blob/stable-2.541/COVERAGE.md#other-dependencies)) | [`2.541.3-k4`](../../releases/tag/2.541.3-k4) | 2026-11-19 | 1 | 30 |
| 2026-11-13 | Jetty 12.1.5 advisories found in 2.541.3's Winstone ([Jetty](../../blob/stable-2.541/COVERAGE.md#jetty)) | [`2.541.3-k3`](../../releases/tag/2.541.3-k3) | 2026-11-15 | 2 | 30 |
| 2026-10-28 | [Jenkins security advisory](https://www.jenkins.io/security/advisory/2026-10-28/), 15 core issues | [`2.541.3-k2`](../../releases/tag/2.541.3-k2) | 2026-10-29 | 1 | 7 |

The 2026-10-28 and 2026-11-13 rows predate this file and are measured the same way. Advisories published before 2026-10-28 were already in the line when it started, so they have no row.

## What we don't do

- **No new features**, and no backports of changes from newer Jenkins that are not security fixes.
- **No plugin backports by default.** The plugin fixes that need a newer core are listed in COVERAGE.md. If you depend on one and can't move to a newer core yet, open an issue, and it gets looked at then.
- **No fix-time SLA.** The release times above are targets.
- **Not an official Jenkins release.** These builds are not covered by Jenkins security advisories, CVE assignments or the Jenkins security team.
