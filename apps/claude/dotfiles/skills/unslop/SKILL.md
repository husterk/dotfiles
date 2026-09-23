---
name: unslop
version: 1.6.0
description: Apply the user's writing standards to prose being drafted: cut AI tells, prefer structure, keep a human voice. Use when writing or revising a PR description, commit body, issue or comment, ADR, README, design doc, or release notes. Also use when the user says a draft reads like AI, sounds generic or corporate, or asks to unslop, humanize, or tighten text.
---

# Unslop

Edit text to remove AI patterns and add human voice.

Adapted from cursor/plugins `pstack/skills/unslop`. Day-to-day reply style lives
in `~/.claude/rules/communication.md`, which is always loaded. This skill is the
deeper pass for prose someone else will read.

## Process

1. Scan the draft against `Patterns to detect and fix`.
2. Rewrite. Preserve meaning, match intended tone.
3. Apply `Adding soul` if the piece is multi-paragraph prose.
4. Run `Pre-send scan`. Check the specific items; do not substitute the vague
   question "does this read as AI".

## Pre-send scan

None of these has an exception. `~/.claude/rules/communication.md` is
authoritative if the two ever disagree.

- No em dashes, en dashes, or double hyphens standing in for punctuation.
- No "one more thing" reveal at the end.
- No unsolicited offer of next steps.
- The opening line answers the question rather than restating it.
- No praise-critique-reassurance sandwich.
- Structure where it aids scanning, not a wall of text.
- No emoji anywhere in code or code comments.
- No announcements of honesty, candor, or fairness.
- US spelling throughout. Run `mise run dev:check-spelling`; do not check by eye.
- No closing recap of what you just said.

## Adding soul

Removing patterns is half the job. Sterile, voiceless writing is just as obvious.
This section applies to multi-paragraph prose, not to short chat replies.

- **Have opinions.** React to facts instead of neutrally listing pros and cons.
- **Vary rhythm.** Short sentences. Then longer ones that take their time.
- **Acknowledge complexity.** "Fast, but it silently drops the last batch" beats "fast".
- **Use "I" when it fits.** First person isn't unprofessional.
- **Don't over-polish the prose.** Uniform sentence length and perfectly
  parallel bullets read as machine-made. Structure the content freely; let the
  sentences inside it vary.
- **Be specific.** Not "this is concerning" but "the retry loop can fire 400 times before the circuit breaker notices".

## Patterns to detect and fix

### Content

1. **Puffery.** "pivotal moment", "testament to", "evolving landscape", "setting the stage for". Cut it, state what happened.
2. **Superficial -ing phrases.** "highlighting...", "ensuring...", "reflecting...", "showcasing...", "fostering...". Delete or replace with the real fact. Extremely common in commit messages and PR descriptions.
3. **Promotional language.** "groundbreaking", "renowned", "seamless", "robust", "best-in-class". Use neutral descriptions.
4. **Vague attributions.** "Experts believe", "stakeholders suggest", "the team feels", "it is generally considered". Name the source or delete.
5. **Formulaic challenges.** "Despite challenges... continues to thrive." Replace with specific facts.

### Language

6. **AI vocabulary.** additionally, crucial, delve, enduring, enhance, fostering, garner, interplay, intricate, landscape (abstract), leverage, pivotal, showcase, tapestry, testament, underscore, vibrant. Replace with plain words.
7. **Fancy ways to say "is".** "serves as", "stands as", "boasts", "features". Say "is" or "has".
8. **"Not just X, but Y."** State the point directly.
9. **Rule of three.** Don't force ideas into groups of three. Use the natural number.
10. **Synonym cycling.** Pick one term and repeat it.
11. **False ranges.** "from X to Y" where X and Y aren't on a meaningful scale.

### Style

12. **Em dashes are banned outright.** No exceptions, in any document. Use a period or a comma. Do not substitute en dashes, double hyphens, or parentheses, which just trade one tell for another. If a thought needs separation, end the sentence.
13. **Colon overuse.** Colons introduce a list or example. Not mid-sentence connectors.
14. **Boldface overuse.** Don't bold every proper noun or acronym.
15. **Inline-header lists.** The tell is a bold label and colon restating the line: "**Performance:** Performance improved...". Convert to prose. A bold lead-in that names the item and is followed by genuinely new detail is fine.
16. **Heading case.** Sentence case in prose. When editing a file that already uses another convention, match the file.
17. **Emoji in code.** Never inside code or code comments, in any language. A compiler, linter, or source-encoding step can misread them. Everywhere else they are welcome; see Conventions below.
18. **Curly quotes.** Replace with straight quotes.
19. **British spellings.** Always US English: `behavior` not `behaviour`, `recognize` not `recognise`, `analyze` not `analyse`, `center` not `centre`, `defense` not `defence`, `labeled` not `labelled`, `judgment` not `judgement`, `gray` not `grey`, `while` not `whilst`, `among` not `amongst`. See `Spelling` in `~/.claude/rules/communication.md` for the full table and the scanner. Never rename an existing identifier, config key, or file name to match, and never correct spelling inside quoted text.
20. **Walls of text.** A paragraph carrying three or more distinct facts should be a table or a list. Structure scans faster than prose.

### Communication artifacts

21. **Chatbot phrases and virtue framing.** "I hope this helps!", "Let me know if...", "Of course!", "Certainly!", "Found the smoking gun!" Remove. Also cut announcements of your own honesty or fairness: "to be honest", "honestly", "the honest answer", "full transparency", "to be fair", "I'll be candid". Honesty is the baseline, so labeling it adds nothing and implies the unlabelled sentences are something less.
22. **Cutoff disclaimers.** "While specific details are limited..." Find sources or remove.
23. **Sycophantic tone.** "Great question!", "You're absolutely right!" Respond directly.
24. **The praise-critique-reassurance sandwich.** Give the assessment directly.
25. **End-of-response padding.** No unsolicited offer of further work. No "one more thing" or "one thing worth flagging" reveal saved for the close. If a point matters, put it where it belongs and state it plainly.
26. **Restating the prompt.** Don't open by repeating the question back.

### Filler

27. **Filler phrases.** "In order to" becomes "To". "Due to the fact that" becomes "Because". Delete "It is important to note that" and "It's worth noting that". Don't open with "Importantly" or "That said".
28. **Excessive hedging.** "could potentially possibly be argued that it might" becomes "may".
29. **Generic conclusions.** "The future looks bright." State specific plans or facts. No numbered "key takeaways" recap.

### Jargon

30. **Abstract metaphor nouns used as filler.** substrate, wedge, vector, locus, vantage, nexus, bedrock, modality, gold-plating, ratchet, evacuate (for moving code), endgame, north star, flywheel. Pick the concrete word: substrate becomes base, wedge in becomes add, vector becomes method, gold-plating becomes more than the job needs, evacuate becomes move out, endgame becomes the last phase. Cut north star and flywheel.

    Exception: harness, API surface, primitive, scaffolding, and paradigm are legitimate when they name the actual thing under discussion. Keep them there. They are slop only when standing in for a plainer word.

### Plain speech

31. **Say what it does, not how it feels.** "the database stays close at hand", "SQL you can read", "types that follow your schema" name a feeling. The fix names the mechanism or a number: "`.toSQL()` returns the exact string sent to the database", "a column rename fails the build". If you can't restate a sentence as a concrete instruction, fact, or number, cut it. If it could appear unchanged in another project's docs, it says nothing about this one. Cut it.
32. **Shorten or split dense sentences.** One idea per sentence. If the reader has to backtrack, break it in two.
33. **Active voice.** Catch "is/are/was/were + past participle" and name the actor: "queries are validated" becomes "the compiler validates queries". Passive is fine only when the actor is unknown or genuinely doesn't matter.
34. **Cut adverbs, or use a stronger verb.** "runs quickly" becomes "is fast" or the number. "significantly improves" becomes the measured delta.
35. **Prefer the plain word.** utilize becomes use, leverage becomes use, facilitate becomes help, numerous becomes many, in the event that becomes if.

## PR and issue specifics

- Lead the description with what changed and why, not with context the reader already has.
- Cut "This PR..." and "This issue...". Start with the change.
- Acceptance criteria are testable statements, not aspirations. "Returns 409 on duplicate submit", not "handles duplicates gracefully".
- Don't pad a test plan when the change is trivial.
- When updating an existing description, rewrite it as a standing statement of the current state. No "previously X, now Y", no appended edit note, no old wording left beside the new. The issue history and the PR commit list already hold the history.
- Never claim a test passed unless it ran. See `Claims and Evidence` in CLAUDE.md.

## Conventions

These are preferences, not defects to hunt.

- **Emoji are welcome everywhere except code.** Use them where they speed up reading: status and severity markers (✅ ⚠️ ❌), section markers, row labels.
- **Structure where the content has it.** Tables, lists, and headings for parallel items, comparisons, or steps. A short table beats a dense paragraph carrying the same facts. A short answer stays plain prose.
- **Technical terms are fine when literal.** harness, API surface, primitive, scaffolding, paradigm. Slop only as filler.
