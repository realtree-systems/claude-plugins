#!/usr/bin/env python3
"""Generate the jyro-code skill from jyro-for-llms.md.

SKILL.md is rendered from tools/jyro/SKILL.md.tmpl; the reference files are
the remaining sections of jyro-for-llms.md, copied verbatim and split by topic.

Usage:
    python3 tools/jyro/build.py [path/to/jyro-for-llms.md] [--check]

Without a path, the document is looked for under $JYRO_DOC, then in a
jyro-doc checkout beside this repository. --check exits 1 when the generated
files differ from what is on disk, without writing anything.
"""

import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
SKILL_DIR = ROOT / "plugins" / "jyro" / "skills" / "jyro-code"
TEMPLATE = ROOT / "tools" / "jyro" / "SKILL.md.tmpl"

# Reference file -> (title, sections of jyro-for-llms.md it holds)
REFERENCES = {
    "language.md": ("Jyro language reference", [4, 5, 6, 7, 8, 9, 10, 11]),
    "stdlib.md": ("Jyro standard library", [12]),
    "errors.md": ("Jyro errors and limits", [13]),
    "patterns.md": ("Jyro examples and patterns", [3, 14]),
    "running.md": ("Running Jyro scripts", [16]),
}
# Sections rendered into SKILL.md itself.
INLINE = [1, 2, 15]


def find_doc(args):
    if args:
        return Path(args[0])
    candidates = []
    if os.environ.get("JYRO_DOC"):
        candidates.append(Path(os.environ["JYRO_DOC"]) / "jyro-for-llms.md")
    for parent in [ROOT.parent, ROOT.parent.parent, Path.home() / "GitHub"]:
        candidates.append(parent / "jyro-doc" / "jyro-for-llms.md")
    for c in candidates:
        if c.is_file():
            return c
    sys.exit("jyro-for-llms.md not found; pass its path or set JYRO_DOC")


def split(text):
    """Return (preamble, {section number: text}) split at '## N. ' headings outside code fences."""
    sections, current, preamble, in_fence = {}, None, [], False
    for line in text.splitlines(keepends=True):
        if line.startswith("```"):
            in_fence = not in_fence
        m = None if in_fence else re.match(r"## (\d+)\. ", line)
        if m:
            current = int(m.group(1))
            sections[current] = []
        (sections[current] if current is not None else preamble).append(line)
    return "".join(preamble), {n: "".join(ls).rstrip() + "\n" for n, ls in sections.items()}


def source_version(doc):
    try:
        sha = subprocess.run(
            ["git", "-C", str(doc.parent), "log", "-1", "--format=%h %cs", "--", doc.name],
            capture_output=True, text=True, check=True,
        ).stdout.strip()
        return f"jyro-doc {sha}" if sha else "jyro-doc (uncommitted)"
    except (OSError, subprocess.CalledProcessError):
        return "jyro-doc (unknown version)"


def build(doc):
    preamble, sections = split(doc.read_text(encoding="utf-8"))
    used = set(INLINE) | {n for _, ns in REFERENCES.values() for n in ns}
    missing = sorted(used - sections.keys())
    unused = sorted(sections.keys() - used)
    if missing:
        sys.exit(f"sections missing from {doc}: {missing}")
    if unused:
        sys.exit(f"sections of {doc} not placed in the skill: {unused}; update REFERENCES in tools/jyro/build.py")

    version = source_version(doc)
    banner = f"<!-- generated from jyro-for-llms.md ({version}) by tools/jyro/build.py; do not edit -->\n\n"

    # Drop the opening "# Jyro for LLMs" title and the line addressed to "a language model".
    conventions = "\n".join(
        p for p in preamble.strip().split("\n\n")[1:] if p.startswith("Conventions")
    )

    out = {}
    skill = TEMPLATE.read_text(encoding="utf-8")
    skill = skill.replace("{{source}}", version)
    skill = skill.replace("{{conventions}}", conventions.strip())
    for n in INLINE:
        skill = skill.replace(f"{{{{section {n}}}}}", sections[n].rstrip())
    leftover = re.findall(r"\{\{[^}]+\}\}", skill)
    if leftover:
        sys.exit(f"unfilled placeholders in template: {leftover}")
    out[SKILL_DIR / "SKILL.md"] = skill

    for name, (title, ns) in REFERENCES.items():
        body = "\n".join(sections[n] for n in ns)
        out[SKILL_DIR / "reference" / name] = f"{banner}# {title}\n\n{body}"
    return out


def main():
    args = [a for a in sys.argv[1:] if a != "--check"]
    check = "--check" in sys.argv[1:]
    doc = find_doc(args)
    files = build(doc)
    stale = [p for p, text in files.items() if not p.is_file() or p.read_text(encoding="utf-8") != text]
    if check:
        for p in stale:
            print(f"out of date: {p.relative_to(ROOT)}")
        sys.exit(1 if stale else 0)
    for p, text in files.items():
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text, encoding="utf-8")
        print(f"{'wrote' if p in stale else 'unchanged'}: {p.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
