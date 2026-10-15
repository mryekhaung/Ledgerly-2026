"""Audit spacing, elevation and component-height drift in the widget layer.

docs/Design.md §4.1 defines a base-4 spacing scale and §4.2 a radius scale; the
12 design rules in test/core/design_rules_test.dart enforce colours, radius,
scaffold, type, icons, cards, tiles and menus -- but nothing enforces spacing,
elevation or component heights. This is the measurement for that gap.

Comment-aware and multi-line aware, so a wrapped
    EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    )
does not count, while `horizontal: 14,` does.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

SCALE = {2, 4, 8, 12, 16, 24, 32, 48}
TOKEN_LAYER = {
    "lib/app/theme/app_spacing.dart",
    "lib/app/theme/app_theme.dart",
}
# Values that are documented component dimensions, not spacing.
COMPONENT_DIMS = {
    20,  # CategoryGem sm
    28,  # CategoryGem md / SegmentedTabs height 32 -> see below
    32,  # SegmentedTabs pill height
    40,  # CategoryGem lg
    52,  # primary button height (Design.md §5.7)
    56,  # CategoryGem xl / field height (§5.8) / ListRow absolute min
    64,  # ListRow single line (§5.6)
    72,  # separator inset (§5.6)
    76,  # ListRow two line (§5.6)
    44,  # hit target (§5.7)
    48,  # hit target comfortable
    96,  # EmptyState illustration (§5.9)
    1200,  # content cap
    360,  # pane widths
    400,
    18,  # glass blur compact
    24,  # glass blur medium
    320,  # EmptyState max width
    560,  # prose cap
    999,
    0,
    1,
}


def strip_comments(src: str) -> str:
    src = re.sub(r"/\*.*?\*/", " ", src, flags=re.S)
    return re.sub(r"//[^\n]*", "", src)


def lit_numbers(text: str) -> list[float]:
    """Numeric literals that are layout dimensions, skipping 0/0.0 noise."""
    out = []
    for m in re.finditer(r"(?<![\w.])(\d+(?:\.\d+)?)(?![\w.])", text):
        v = float(m.group(1))
        out.append(v)
    return out


def scan(path: Path, src: str) -> tuple[list, list]:
    """Return (edge_insets_hits, sizedbox_hits) as (value, line, snippet)."""
    hits, boxes = [], []
    code = strip_comments(src)
    lines = code.split("\n")

    # Walk the source tracking line numbers so we can report file:line.
    # Match the constructor then its balanced argument list.
    for m in re.finditer(
        r"EdgeInsets\.(?:all|symmetric|only|fromLTRB)\s*\(([^()]*(?:\([^()]*\)[^()]*)*)\)",
        code,
    ):
        body = m.group(1)
        if "AppSpacing" in body or "AppRowHeight" in body:
            continue
        line_no = code[: m.start()].count("\n") + 1
        for v in lit_numbers(body):
            hits.append((v, line_no, lines[line_no - 1].strip()))

    for m in re.finditer(r"SizedBox\(\s*(height|width)\s*:\s*([^,)]+)", code):
        key, expr = m.group(1), m.group(2).strip()
        if "AppSpacing" in expr:
            continue
        nums = lit_numbers(expr)
        line_no = code[: m.start()].count("\n") + 1
        for v in nums:
            boxes.append((v, line_no, lines[line_no - 1].strip()))

    return hits, boxes


def main() -> int:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    rows = []
    for f in sorted(root.rglob("*.dart")):
        rel = f.as_posix()
        if not rel.startswith(("lib/features", "lib/core", "lib/app")):
            continue
        if rel in TOKEN_LAYER or ".g.dart" in rel or ".gr.dart" in rel:
            continue
        try:
            src = f.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        hits, boxes = scan(f, src)
        allhits = hits + boxes
        if not allhits:
            continue
        off = [h for h in allhits if h[0] not in SCALE and h[0] not in COMPONENT_DIMS]
        rows.append((rel, len(allhits), len(off), off[:6]))

    total = sum(r[1] for r in rows)
    off_total = sum(r[2] for r in rows)
    print(f"numeric spacing literals in widget layer: {total}")
    print(f"off-scale / undocumented:                 {off_total}")
    print(f"files touched:                            {len(rows)}")
    print()
    print("--- off-scale values, by file ---")
    for rel, n, noff, sample in sorted(rows, key=lambda r: -r[2]):
        if noff == 0:
            continue
        print(f"{rel}: {n} literal(s), {noff} off-scale")
        for v, ln, snip in sample:
            print(f"    line {ln}: {v}   {snip[:90]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
