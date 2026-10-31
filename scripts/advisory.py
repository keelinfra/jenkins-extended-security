#!/usr/bin/env python3
"""Summarize a Jenkins security advisory for a line's base version.

For each advisory date given, prints one row for the README's Advisories
table: how many core issues it has, and how many of the fixed plugin versions
it names install on the base version (default 2.541.3), with the ones that
don't. Details on what blocks a plugin go to stderr.

"Installs" means the fixed version, and the minimum version of each required
(non-optional) dependency, recursively, declare a required core no newer than
the base, according to the update center's plugin-versions.json. Nothing is
booted; plugins the advisory lists without a fix are not counted.

    scripts/advisory.py 2026-09-16
    scripts/advisory.py --base 2.541.3 2026-04-29 2026-05-27

Standard library only.
"""

import argparse
import html
import json
import re
import sys
import urllib.request

ADVISORY_URL = "https://www.jenkins.io/security/advisory/{}/"
UPDATE_CENTER = "https://updates.jenkins.io/current/update-center.actual.json"
PLUGIN_VERSIONS = "https://updates.jenkins.io/current/plugin-versions.json"


def fetch(url):
    with urllib.request.urlopen(url, timeout=120) as r:
        return r.read().decode("utf-8")


def text(fragment):
    return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", fragment))).strip()


def vkey(version):
    return [int(x) for x in re.findall(r"\d+", version)]


def section(page, heading):
    """The <ul> right after an <h2> with this heading."""
    m = re.search(r"<h2[^>]*>\s*" + heading + r"\s*</h2>\s*<ul>(.*?)</ul>", page, re.S)
    return m.group(1) if m else ""


def parse(page):
    """(core issue count, [(display name, fixed version)])"""
    affected = [text(li) for li in re.findall(r"<li>(.*?)</li>", section(page, "Affected Versions"), re.S)]
    has_core = any(a.startswith("Jenkins weekly") or a.startswith("Jenkins LTS") for a in affected)
    core = 0
    if has_core:
        # Core issues are the descriptions without an "Affected plugin:" line,
        # minus other non-plugin deliverables such as update-center2.
        body = page.split(">Descriptions<", 1)[-1].split(">Severity<", 1)[0]
        for block in re.split(r"<h3[^>]*>", body)[1:]:
            t = text(block)
            title = t.split(" SECURITY-", 1)[0]
            if "Affected plugin" in t or "update-center2" in title or not re.search(r"SECURITY-\d+", t):
                continue
            core += 1
    fixes = []
    for li in re.findall(r"<li>(.*?)</li>", section(page, "Fix"), re.S):
        m = re.match(r"(.*?) should be updated to version (\S+)", text(li))
        if m and not m.group(1).startswith("Jenkins"):
            fixes.append((m.group(1), m.group(2)))
    return core, fixes


class Plugins:
    def __init__(self):
        uc = json.loads(fetch(UPDATE_CENTER))["plugins"]
        self.by_title = {p.get("title", "").strip().lower(): pid for pid, p in uc.items()}
        self.versions = json.loads(fetch(PLUGIN_VERSIONS))["plugins"]

    def plugin_id(self, display_name):
        title = re.sub(r"\s*Plugin$", "", display_name).strip().lower()
        return self.by_title.get(title) or self.by_title.get(display_name.lower())

    def blockers(self, pid, version, base, seen=None):
        """What keeps pid:version off base: entries whose requiredCore is newer, or unknown versions."""
        seen = set() if seen is None else seen
        if (pid, version) in seen:
            return []
        seen.add((pid, version))
        entry = self.versions.get(pid, {}).get(version)
        if entry is None:
            return [f"{pid} {version} not in the update center"]
        out = []
        if vkey(entry["requiredCore"]) > vkey(base):
            out.append(f"{pid} {version} needs {entry['requiredCore']}")
        for dep in entry.get("dependencies", []):
            if not dep.get("optional"):
                out += self.blockers(dep["name"], dep["version"], base, seen)
        return out


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--base", default="2.541.3", help="base Jenkins version of the line (default 2.541.3)")
    ap.add_argument("dates", nargs="+", help="advisory dates, YYYY-MM-DD")
    args = ap.parse_args()

    plugins = Plugins()
    for date in args.dates:
        core, fixes = parse(fetch(ADVISORY_URL.format(date)))
        ok, not_ok = 0, []
        for name, version in fixes:
            pid = plugins.plugin_id(name)
            if pid is None:
                # Not a plugin in the update center (for example update-center2).
                print(f"  {date}: skipped {name} {version}: no such plugin", file=sys.stderr)
                continue
            b = plugins.blockers(pid, version, args.base)
            if b:
                not_ok.append(f"{pid} ({b[0].split(' needs ')[-1] if ' needs ' in b[0] else b[0]})")
                print(f"  {date}: {'; '.join(b)}", file=sys.stderr)
            else:
                ok += 1
        total = ok + len(not_ok)
        if total == 0:
            plugin_cell = "none in this advisory"
        else:
            plugin_cell = f"{ok} of {total}"
            if not_ok:
                plugin_cell += "; not: " + ", ".join(not_ok)
        link = f"[{date}]({ADVISORY_URL.format(date)})"
        # The line column starts as the advisory-day status; edit it when the release is out.
        line_cell = "nothing to patch" if core == 0 else "backport in progress"
        print(f"| {link} | {core} | {line_cell} | {plugin_cell} |")


if __name__ == "__main__":
    main()
