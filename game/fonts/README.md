# Fonts

## noto_sans_jp_subset.ttf

Noto Sans JP, Regular (weight 400), cut down to the characters the game uses so Japanese
terms (はい, 月次締め, ...) render on the web build, which has no system fonts.

- Source: official Google Fonts repository,
  `https://github.com/google/fonts/tree/main/ofl/notosansjp` (`NotoSansJP[wght].ttf`).
- License: SIL Open Font License 1.1, see `OFL.txt` next to this file.
- Contains: Latin, Latin-1, general and CJK punctuation, hiragana, katakana, full-width
  forms, and every CJK character found in `game/case/templates/*.json`,
  `game/artifacts/*.json` and `game/dialogue/*.json`.

### Rebuild after adding Japanese text

`tests/unit/test_jp_font_coverage.gd` fails when a data file uses a character the subset
does not have. Rebuild with:

```bash
python3 -m venv /tmp/fontvenv && /tmp/fontvenv/bin/pip install "fonttools>=4,<5"
curl -L -o /tmp/NotoSansJP-VF.ttf "https://raw.githubusercontent.com/google/fonts/main/ofl/notosansjp/NotoSansJP%5Bwght%5D.ttf"
/tmp/fontvenv/bin/python tools/subset_jp_font.py /tmp/NotoSansJP-VF.ttf
```

Run the last command from the repository root.
