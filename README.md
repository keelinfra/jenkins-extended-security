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

Each line lives on its own branch, with the patches, a build script and tests. No binaries are published: you build the WAR from source.

| Line | Base | Java | Branch | Covers advisories up to |
| --- | --- | --- | --- | --- |
| 2.541.x | 2.541.3, the last LTS on Java 17 | 17 | [`stable-2.541`](../../tree/stable-2.541) | 2026-10-28 |

Only Jenkins core, Remoting and Stapler are patched. Plugins are not.

## Security

See [SECURITY.md](SECURITY.md).

## License

This repository's own files are MIT, see [LICENSE](LICENSE). The patches keep the license of the project they come from: MIT for Jenkins and Remoting, BSD 2-Clause for Stapler. Each line's branch has the full texts in `LICENSES/`.
