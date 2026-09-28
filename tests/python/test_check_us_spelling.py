import os
import tempfile
import unittest

from helpers import load

spelling = load("check-us-spelling")


def scan(text):
    with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False) as handle:
        handle.write(text)
    try:
        return [(found, want) for _, found, want, _ in spelling.scan_file(handle.name)]
    finally:
        os.unlink(handle.name)


class ScanFile(unittest.TestCase):
    def test_flags_british_forms(self):
        self.assertEqual(
            scan("The colour and the behaviour.\n"),
            [("colour", "color"), ("behaviour", "behavior")],
        )

    def test_flags_inflected_forms(self):
        self.assertEqual(
            scan("It was cancelled and recognised.\n"),
            [("cancelled", "canceled"), ("recognised", "recognized")],
        )

    def test_ignores_inline_code(self):
        self.assertEqual(scan("Call `serialise()` on the `colour` key.\n"), [])

    def test_ignores_fenced_blocks(self):
        self.assertEqual(scan("```\ncolour = 1\n```\nplain text\n"), [])

    def test_us_text_is_clean(self):
        self.assertEqual(scan("The color and behavior are recognized.\n"), [])


class StripCode(unittest.TestCase):
    def test_keeps_line_count(self):
        text = "a\n```\nb\n```\nc"
        self.assertEqual(len(spelling.strip_code(text)), len(text.split("\n")))


if __name__ == "__main__":
    unittest.main()
