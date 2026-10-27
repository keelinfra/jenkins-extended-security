# Coverage

Core issues from the Jenkins security advisories published after 2.541.3, and where each fix comes from. Upstream commits are in [jenkinsci/jenkins](https://github.com/jenkinsci/jenkins), [jenkinsci/remoting](https://github.com/jenkinsci/remoting) and [jenkinsci/stapler](https://github.com/jenkinsci/stapler).

Plugin issues are not covered. Install the fixed plugin versions; most of them still install on 2.541.3.

## 2026-06-10

| Issue | CVE | Patch | Upstream commit | Notes |
| --- | --- | --- | --- | --- |
| SECURITY-3707 | CVE-2026-53435 | jenkins/0002 | d739f6a626 | |
| SECURITY-3711, SECURITY-3755 | CVE-2026-53436, CVE-2026-53437 | jenkins/0004 | b32f2f27a8 | |
| SECURITY-3712 | CVE-2026-53438 | jenkins/0005 | a154e1108f | |
| SECURITY-3713 | CVE-2026-53439 | jenkins/0006 | 0586de4255 | |
| SECURITY-3721 | CVE-2026-53440 | jenkins/0007 | 38071826c9 | |
| SECURITY-3731 | CVE-2026-53441 | jenkins/0003 | 7c5fc12d3e | |
| SECURITY-3744 | CVE-2026-53442 | jenkins/0008 | 206f0b565f | |

## 2026-08-05

| Issue | CVE | Patch | Upstream commit | Notes |
| --- | --- | --- | --- | --- |
| SECURITY-3911 | CVE-2026-70426 | remoting/0001, jenkins/0025 | 931d3c9929 (Remoting) | Upstream moved core to a newer Remoting. Here the fix is applied to the 3352 line that 2.541.3 ships, as Remoting 3352.k2541.1. |
| SECURITY-3916 | CVE-2026-70430 | jenkins/0009, 0029, 0030 | ae40f05823 | Fix unchanged. The test is adapted: 2.541.x has Overall/Manage off by default and its global config form still needs `computerRetentionCheckInterval`. |
| SECURITY-3924 | CVE-2026-70429 | jenkins/0010 | 0e88fcee42 | |
| SECURITY-3927 | CVE-2026-70428 | jenkins/0011 | ce45d8b852 | |
| SECURITY-3930 | CVE-2026-70427 | jenkins/0012, 0028 | b27f846775 | 0028 adds a test import missing on 2.541.x. |
| SECURITY-3657 follow-up | none | jenkins/0001 | 3a903122db | "Limit SECURITY-3657 fix to controller JVM" (#26709), a follow-up fix shipped in the same LTS. |

## 2026-09-02

| Issue | CVE | Patch | Upstream commit | Notes |
| --- | --- | --- | --- | --- |
| SECURITY-3878 | CVE-2026-84649 | stapler/0004, jenkins/0026 | d7c3e58008 (Stapler), 95e24c6cfa | Upstream moved core to Stapler 2088, which needs commons-fileupload2 M5 (renamed methods that plugins may call). Here the fix is applied to the 2050 line that 2.541.3 ships, as Stapler 2050.k2541.1. |
| SECURITY-3879 | CVE-2026-84655 | stapler/0003, jenkins/0015 | 72e7fba79c (Stapler), e66b1900ce | |
| SECURITY-3908 | CVE-2026-84646 | jenkins/0019 | e7a5ee1107 | |
| SECURITY-3915 | CVE-2026-84647 | stapler/0001, jenkins/0013 | f76c715d7e (Stapler), 6f149299d5 | |
| SECURITY-3926 | CVE-2026-84654 | stapler/0002, jenkins/0014 | 077d046f15 (Stapler), ab7d8703cc | |
| SECURITY-3967 | CVE-2026-84648 | jenkins/0020 | bc925ea466 | |
| SECURITY-3972 | CVE-2026-84645 | jenkins/0018 | e174eeb116 | |
| SECURITY-3981 | CVE-2026-84653 | jenkins/0022 | 02282cd301 | |
| SECURITY-4006 | CVE-2026-84656 | jenkins/0016 | a853df5a24 | |
| SECURITY-4015 | CVE-2026-84657 | jenkins/0021 | 23ef179aa5 | |
| SECURITY-4016 | CVE-2026-84652 | jenkins/0017 | caf1847af2 | |
| SECURITY-4025 | CVE-2026-84651 | jenkins/0024 | fbc5ce3718 | |
| SECURITY-4032 | CVE-2026-84650 | jenkins/0023, 0027 | c29adc6755 | 2.541 has no `Cause.causeBag` field, so that annotation is dropped. `DefaultCrumbIssuer.excludeClientIPFromCrumb` is not transient on 2.541 and stays as it is. |
