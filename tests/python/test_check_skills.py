import os
import tempfile
import unittest

from helpers import load

skills = load("check-skills")

GOOD = """---
name: demo
description: A demo skill used by the tests.
---

# demo

Plain body.
"""


def audit_with(files):
    """Write {relative path: content} under a temp root and audit it."""
    root = tempfile.mkdtemp()
    for rel, content in files.items():
        path = os.path.join(root, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as handle:
            handle.write(content)
    problems, counts = skills.audit(root)
    return [p.message for p in problems], counts


class Audit(unittest.TestCase):
    def test_valid_skill_passes(self):
        messages, counts = audit_with({"skills/demo/SKILL.md": GOOD})
        self.assertEqual(messages, [])
        self.assertEqual(counts["skills"], 1)

    def test_name_must_match_directory(self):
        messages, _ = audit_with({"skills/other/SKILL.md": GOOD})
        self.assertTrue(any("name" in m for m in messages), messages)

    def test_unknown_key_is_reported(self):
        text = GOOD.replace("name: demo\n", "name: demo\nnmae: typo\n")
        messages, _ = audit_with({"skills/demo/SKILL.md": text})
        self.assertTrue(any("nmae" in m for m in messages), messages)

    def test_em_dash_in_prose_is_reported(self):
        text = GOOD.replace("Plain body.", "Plain body — with a dash.")
        messages, _ = audit_with({"skills/demo/SKILL.md": text})
        self.assertTrue(any("dash" in m for m in messages), messages)

    def test_missing_skill_md_is_reported(self):
        messages, _ = audit_with({"skills/empty/README.txt": "x"})
        self.assertTrue(any("no SKILL.md" in m for m in messages), messages)


if __name__ == "__main__":
    unittest.main()
