"""Rebuild game/fonts/noto_sans_jp_subset.ttf from the official Noto Sans JP variable font.

Keeps Latin, punctuation, kana and every CJK character used in the game's JSON data, so
Japanese terms render on the web build without shipping the full ~10 MB font.

Usage (fonttools in a throwaway venv, not a project dependency):
    python3 -m venv /tmp/fontvenv && /tmp/fontvenv/bin/pip install "fonttools>=4,<5"
    curl -L -o /tmp/NotoSansJP-VF.ttf \
      "https://raw.githubusercontent.com/google/fonts/main/ofl/notosansjp/NotoSansJP%5Bwght%5D.ttf"
    /tmp/fontvenv/bin/python tools/subset_jp_font.py /tmp/NotoSansJP-VF.ttf

Run it again whenever new Japanese text is added to the data files; the GUT test
test_jp_font_coverage.gd fails until you do.
"""

import pathlib
import sys

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

ROOT = pathlib.Path(__file__).resolve().parent.parent
DATA_GLOBS = ["game/case/templates/*.json", "game/artifacts/*.json"]
OUTPUT = ROOT / "game/fonts/noto_sans_jp_subset.ttf"

# Latin, Latin-1, general punctuation, CJK punctuation, kana, full-width forms.
BASE_RANGES = [
    (0x0020, 0x007E), (0x00A0, 0x00FF), (0x2000, 0x206F),
    (0x3000, 0x303F), (0x3040, 0x309F), (0x30A0, 0x30FF), (0xFF00, 0xFFEF),
]


def is_cjk(char: str) -> bool:
    return 0x3000 <= ord(char) <= 0x9FFF or 0xF900 <= ord(char) <= 0xFAFF or 0xFF00 <= ord(char) <= 0xFFEF


def data_characters() -> set[int]:
    codepoints: set[int] = set()
    for pattern in DATA_GLOBS:
        for path in sorted(ROOT.glob(pattern)):
            codepoints.update(ord(c) for c in path.read_text(encoding="utf-8") if is_cjk(c))
    return codepoints


def main(source: str) -> None:
    font = TTFont(source)
    # Pin the variable font to Regular so the subset is a plain static font.
    font = instancer.instantiateVariableFont(font, {"wght": 400}, updateFontNames=True)
    unicodes = set(data_characters())
    for start, end in BASE_RANGES:
        unicodes.update(range(start, end + 1))
    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.notdef_outline = True
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes=sorted(unicodes))
    subsetter.subset(font)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    font.save(OUTPUT)
    print(f"wrote {OUTPUT.relative_to(ROOT)}: {OUTPUT.stat().st_size} bytes")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
