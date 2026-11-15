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

## What we don't do

- **No new features**, and no backports of changes from newer Jenkins that are not security fixes.
- **No plugin backports by default.** The plugin fixes that need a newer core are listed in COVERAGE.md. If you depend on one and can't move to a newer core yet, open an issue, and it gets looked at then.
- **No fix-time SLA.** The release times above are targets.
- **Not an official Jenkins release.** These builds are not covered by Jenkins security advisories, CVE assignments or the Jenkins security team.
