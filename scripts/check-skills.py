#!/usr/bin/env python3
"""Structural audit for Claude Code skill and agent definitions.

A skill or agent is loaded by its frontmatter, so a defect there is invisible
until Claude silently declines to use the file. The failures that actually
happen are mechanical: a `name` that no longer matches its directory after a
rename, a `references/` file the SKILL.md stopped pointing at, a reference to a
file that was never created, a description too long for the loader.

This checks that class rather than judging content. It is deliberately generic:
it makes no assumption about which skills exist, so it keeps working as they
are added and removed.

    ./check-skills.py apps/claude/dotfiles
    ./check-skills.py ~/.claude

Given a directory, it looks for `skills/` and `agents/` beneath it. Exits 0 when
every check passes, 1 otherwise.
"""

import os
import re
import sys

# The loader truncates past this, so a longer description silently loses its
# tail rather than erroring.
MAX_DESCRIPTION = 1024

# Banned in prose by rules/communication.md. Checked here because a skill file
# is prose that Claude reads back and imitates.
DASHES = {"—": "em dash", "–": "en dash"}

# Frontmatter keys Claude Code recognizes. An unknown key is usually a typo,
# and a typo'd key is silently ignored rather than rejected.
# From https://code.claude.com/docs/en/skills and /en/sub-agents. `version`
# predates those tables and is kept for existing skills.
SKILL_KEYS = {
    "name",
    "description",
    "when_to_use",
    "argument-hint",
    "arguments",
    "disable-model-invocation",
    "user-invocable",
    "allowed-tools",
    "disallowed-tools",
    "model",
    "effort",
    "context",
    "agent",
    "background",
    "hooks",
    "paths",
    "shell",
    "metadata",
    "license",
    "compatibility",
    "version",
}
AGENT_KEYS = {
    "name",
    "description",
    "tools",
    "disallowedTools",
    "model",
    "permissionMode",
    "maxTurns",
    "skills",
    "mcpServers",
    "hooks",
    "memory",
    "background",
    "omitClaudeMd",
    "effort",
    "isolation",
    "color",
    "initialPrompt",
    "experimental",
}


class Problem:
    def __init__(self, path, message):
        self.path = path
        self.message = message


def parse_frontmatter(text):
    """Return (mapping, body, error).

    Only the scalar and inline-list shapes that skill frontmatter actually uses
    are understood. A block list under a key is collapsed to a list of strings.
    """
    lines = text.split("\n")
    if not lines or lines[0].strip() != "---":
        return None, text, "no frontmatter (file must open with ---)"
    try:
        end = lines.index("---", 1)
    except ValueError:
        return None, text, "frontmatter is not closed with ---"

    mapping = {}
    key = None
    for raw in lines[1:end]:
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        if raw.lstrip().startswith("- ") and key is not None:
            mapping.setdefault(key, [])
            if isinstance(mapping[key], list):
                mapping[key].append(raw.lstrip()[2:].strip())
            continue
        if ":" not in raw:
            return None, text, f"cannot parse frontmatter line: {raw.strip()}"
        key, _, value = raw.partition(":")
        key = key.strip()
        value = value.strip()
        mapping[key] = value if value else None
    return mapping, "\n".join(lines[end + 1 :]), None


def referenced_paths(body):
    """Relative paths the body points at: markdown links plus bare code spans."""
    found = set()
    for match in re.finditer(r"\[[^\]]*\]\(([^)]+)\)", body):
        found.add(match.group(1))
    # `references/gates.md` and `scripts/preflight.sh` are how these files are
    # cited far more often than as markdown links.
    for match in re.finditer(r"`([^`\n]+?\.(?:md|sh|py|json|toml|ya?ml))`", body):
        found.add(match.group(1))
    cleaned = set()
    for item in found:
        item = item.split("#", 1)[0].strip()
        if not item or item.startswith(("http://", "https://", "mailto:", "/", "~")):
            continue
        # `hosts/<hostname>/host-manifest.toml` is a shape, not a path.
        if "<" in item or ">" in item or "*" in item:
            continue
        cleaned.add(item)
    return cleaned


def find_repo_root(start):
    """Nearest ancestor holding .git, or None."""
    current = os.path.abspath(start)
    while True:
        if os.path.exists(os.path.join(current, ".git")):
            return current
        parent = os.path.dirname(current)
        if parent == current:
            return None
        current = parent


def check_dashes(path, text, problems):
    for number, line in enumerate(text.split("\n"), 1):
        for char, label in DASHES.items():
            if char in line:
                problems.append(
                    Problem(path, f"line {number}: {label} in prose (use a period or comma)")
                )
                break


def check_unit(path, expected_name, allowed_keys, kind, problems, own_dir=None):
    """Validate one SKILL.md or agent file. Returns the parsed body."""
    with open(path, encoding="utf-8") as handle:
        text = handle.read()
    mapping, body, error = parse_frontmatter(text)
    if error:
        problems.append(Problem(path, error))
        return None

    name = mapping.get("name")
    if not name:
        problems.append(Problem(path, "frontmatter has no `name`"))
    elif name != expected_name:
        problems.append(
            Problem(path, f"`name: {name}` does not match {kind} name `{expected_name}`")
        )

    description = mapping.get("description")
    if not description:
        problems.append(Problem(path, "frontmatter has no `description`"))
    elif len(description) > MAX_DESCRIPTION:
        problems.append(
            Problem(
                path,
                f"description is {len(description)} chars, over the {MAX_DESCRIPTION} limit",
            )
        )

    for key in sorted(set(mapping) - allowed_keys):
        problems.append(Problem(path, f"unknown frontmatter key `{key}`"))

    check_dashes(path, text, problems)

    if own_dir is None:
        return body

    # Every path the body cites must exist, and every file in the directory
    # must be cited by something. A file nothing points at is dead weight the
    # loader still ships.
    # A project-scoped skill legitimately cites repo files by their
    # root-relative path, so a reference resolves against either base.
    cited = referenced_paths(body)
    bases = [own_dir]
    repo_root = find_repo_root(own_dir)
    if repo_root:
        bases.append(repo_root)
    for target in sorted(cited):
        if not any(os.path.exists(os.path.join(b, target)) for b in bases):
            problems.append(Problem(path, f"references missing file `{target}`"))

    on_disk = set()
    for root, _, names in os.walk(own_dir):
        for fname in names:
            rel = os.path.relpath(os.path.join(root, fname), own_dir)
            if rel != "SKILL.md" and not rel.startswith("."):
                on_disk.add(rel)
    cited = cited | set(os.path.basename(c) for c in cited)
    for orphan in sorted(on_disk - cited):
        problems.append(Problem(path, f"`{orphan}` exists but SKILL.md never references it"))
    return body


def audit(root):
    problems = []
    counts = {"skills": 0, "agents": 0}

    skills_dir = os.path.join(root, "skills")
    if os.path.isdir(skills_dir):
        for entry in sorted(os.listdir(skills_dir)):
            own = os.path.join(skills_dir, entry)
            if not os.path.isdir(own) or entry.startswith("."):
                continue
            skill_md = os.path.join(own, "SKILL.md")
            if not os.path.isfile(skill_md):
                problems.append(Problem(own, "skill directory has no SKILL.md"))
                continue
            counts["skills"] += 1
            check_unit(skill_md, entry, SKILL_KEYS, "directory", problems, own)

    agents_dir = os.path.join(root, "agents")
    if os.path.isdir(agents_dir):
        for entry in sorted(os.listdir(agents_dir)):
            if not entry.endswith(".md") or entry.startswith("."):
                continue
            counts["agents"] += 1
            check_unit(os.path.join(agents_dir, entry), entry[:-3], AGENT_KEYS, "file", problems)

    return problems, counts


def main(argv):
    if len(argv) < 2:
        sys.stderr.write(__doc__)
        return 2

    problems = []
    counts = {"skills": 0, "agents": 0}
    for root in argv[1:]:
        if not os.path.isdir(root):
            sys.stderr.write(f"no such directory: {root}\n")
            return 3
        found, seen = audit(root)
        problems += found
        for key in counts:
            counts[key] += seen[key]

    if not counts["skills"] and not counts["agents"]:
        sys.stderr.write("no skills/ or agents/ found under: {}\n".format(" ".join(argv[1:])))
        return 3

    if problems:
        current = None
        for problem in problems:
            if problem.path != current:
                current = problem.path
                print(current)
            print(f"    {problem.message}")
        print(
            f"\n  FAIL  {len(problems)} problem(s) across {counts['skills']} skill(s)"
            f" and {counts['agents']} agent(s)"
        )
        return 1

    print(f"  PASS  {counts['skills']} skill(s) and {counts['agents']} agent(s) valid")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
