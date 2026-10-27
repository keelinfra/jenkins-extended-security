# Extended Security for Jenkins

Jenkins core security fixes, backported to the last LTS line that runs on each Java version, for controllers that can't move to a newer Java yet.

> This is not an official Jenkins release. It is not covered by Jenkins security advisories, CVE assignments or the Jenkins security team. The way off an old line is to [move to a newer Java](https://www.jenkins.io/doc/book/platform-information/upgrade-java-to-21/) and the current LTS; this only covers the time until you can.

## Lines

Each line lives on its own branch, with the patches, a build script and tests. No binaries are published: you build the WAR from source.

| Line | Base | Java | Branch | Covers advisories up to |
| --- | --- | --- | --- | --- |
| 2.541.x | 2.541.3, the last LTS on Java 17 | 17 | [`stable-2.541`](../../tree/stable-2.541) | 2026-09-02 |

Only Jenkins core, Remoting and Stapler are patched. Plugins are not.

## Security

See [SECURITY.md](SECURITY.md).

## License

This repository's own files are MIT, see [LICENSE](LICENSE). The patches keep the license of the project they come from: MIT for Jenkins and Remoting, BSD 2-Clause for Stapler. Each line's branch has the full texts in `LICENSES/`.
