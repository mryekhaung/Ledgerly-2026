"""Contrast + surface-ramp audit for ledgerly's semantic colour tokens.

WCAG 2.1. The token values are **read from `lib/app/theme/app_colors.dart`**, not
hardcoded here — an earlier version of this script carried a frozen copy of the
pre-§K palette and went on reporting an invisible selected day for months after
it had been fixed. A stale audit is worse than no audit, so this one parses the
source of truth and can never disagree with it.

Run from the repo root:

    python tool/audit_contrast.py
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

COLORS = Path('lib/app/theme/app_colors.dart')

PALETTE_RE = re.compile(
    r'static const (\w+) = Color\(0x([0-9A-Fa-f]{8})\);'
)
GETTER_RE = re.compile(r'Color get (\w+) =>\s*(.+?);', re.S)


def resolve(expr: str, palette: dict[str, str]) -> str:
    """Turn a getter body into a `#RRGGBB` string."""
    expr = expr.strip()
    literal = re.fullmatch(r'const Color\(0x([0-9A-Fa-f]{8})\)', expr)
    if literal:
        return '#' + literal.group(1)[2:]
    named = re.fullmatch(r'AppPalette\.(\w+)', expr)
    if named:
        try:
            return palette[named.group(1)]
        except KeyError:  # pragma: no cover - guards a renamed palette entry
            raise SystemExit(f'unknown palette entry: {expr}')
    raise SystemExit(f'cannot resolve token expression: {expr!r}')


def parse() -> tuple[dict[str, str], dict[str, str], dict[str, str]]:
    src = COLORS.read_text(encoding='utf-8')

    palette = {
        name: '#' + hexval[2:]
        for name, hexval in PALETTE_RE.findall(src)
    }
    if len(palette) < 10:
        raise SystemExit('palette parse failed — the file shape changed')

    out = {}
    for cls in ('AppColorsLight', 'AppColorsDark'):
        start = src.index(f'final class {cls}')
        end = src.index('\n}\n', start)
        body = src[start:end]
        toks = {
            name: resolve(expr, palette)
            for name, expr in GETTER_RE.findall(body)
        }
        out[cls] = toks

    return palette, out['AppColorsLight'], out['AppColorsDark']


PALETTE, LIGHT, DARK = parse()


def lin(c: int) -> float:
    s = c / 255.0
    return s / 12.92 if s <= 0.03928 else ((s + 0.055) / 1.055) ** 2.4


def lum(hexstr: str) -> float:
    h = hexstr.lstrip('#')
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)


def lstar(hexstr: str) -> float:
    y = lum(hexstr)
    return 116.0 * (y ** (1 / 3)) - 16 if y > 0.008856 else 903.3 * y


def ratio(a: str, b: str) -> float:
    la, lb = lum(a), lum(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def lerp(a: str, b: str, t: float) -> str:
    ha, hb = a.lstrip('#'), b.lstrip('#')
    out = []
    for i in (0, 2, 4):
        ca, cb = int(ha[i:i + 2], 16), int(hb[i:i + 2], 16)
        out.append(round(ca + (cb - ca) * t))
    return '#%02X%02X%02X' % tuple(out)


CAPSULE_START = 0.66  # day_cell.dart, mirrored in design_tokens_test.dart
TEXT_PAIRS = ['textPrimary', 'textSecondary', 'textTertiary']
MARK_PAIRS = ['brandSubtle', 'moneyOutSubtle', 'moneyInSubtle',
              'moneyOut', 'moneyIn', 'brandPrimary', 'border']
SURFACES = ['surfaceSunken', 'surface', 'surfaceSubtle', 'surfaceRaised']


def report(name: str, t: dict) -> None:
    print(f'===== {name} (surface {t["surface"]}) =====')
    print('-- text on surface (AA small text needs 4.5) --')
    for k in TEXT_PAIRS:
        r = ratio(t[k], t['surface'])
        flag = 'FAIL' if r < 4.5 else ('large-only' if r < 7 else 'OK')
        print(f'  {k:16} {t[k]}  {r:5.2f}:1  {flag}')
    print('-- marks/fills on surface (a visible non-text mark needs 3.0) --')
    for k in MARK_PAIRS:
        r = ratio(t[k], t['surface'])
        flag = 'FAIL' if r < 3.0 else 'OK'
        print(f'  {k:16} {t[k]}  {r:5.2f}:1  {flag}')
    print('  (A FAIL here is expected for the *Subtle tints and `border`: they')
    print('   are tints and hairlines, not state fills. §2.6.1 exempts a tint')
    print('   below 3:1 when the state is also carried by a filled icon, a weight')
    print('   change or a border, and §2.2 scopes `border` to separators only.)')
    print('-- text on its own brand fill --')
    print(f'  textOnBrand on brandPrimary: '
          f'{ratio(t["textOnBrand"], t["brandPrimary"]):5.2f}:1')
    print('-- capsule ramp: step 1..4 vs surface --')
    for fam, subtle, full in (('expense', 'moneyOutSubtle', 'moneyOut'),
                              ('income', 'moneyInSubtle', 'moneyIn')):
        for step in (1, 2, 3, 4):
            t_ = CAPSULE_START + (1 - CAPSULE_START) * (step - 1) / 3
            c = lerp(t[subtle], t[full], t_)
            r = ratio(c, t['surface'])
            flag = 'INVISIBLE' if r < 2.5 else 'OK'
            print(f'  {fam:8} step {step}  {c}  {r:5.2f}:1  {flag}')
    print()


report('LIGHT', LIGHT)
report('DARK', DARK)

print('===== SURFACE RAMP (docs/Design.md §2.7) =====')
for name, t in (('light', LIGHT), ('dark', DARK)):
    lums = [lum(t[k]) for k in SURFACES]
    ordered = lums == sorted(lums)
    print(f'  {name:5} ' + '  '.join(
        f'{k}={t[k]} L*{lstar(t[k]):5.1f}' for k in SURFACES))
    print(f'        ascending: {ordered}'
          f'{"   <-- BROKEN" if not ordered else ""}')
    sep = ratio(t['surfaceRaised'], t['surface'])
    print(f'        card-vs-page separation: {sep:.4f}:1'
          f'{"   <-- INVISIBLE CARD" if sep < 1.05 else ""}')

lsep = ratio(LIGHT['surfaceRaised'], LIGHT['surface'])
dsep = ratio(DARK['surfaceRaised'], DARK['surface'])
drift = (dsep - lsep) / lsep * 100
print(f'  cross-mode card-lift drift: {drift:+.1f}%'
      f'{"   <-- OVER 30%" if abs(drift) > 30 else ""}')
print()

print('===== AA on every surface each role can land on =====')
for name, t in (('light', LIGHT), ('dark', DARK)):
    print(f'  {name}')
    for surf in SURFACES:
        cells = []
        for role in ('textPrimary', 'textSecondary', 'textTertiary',
                     'moneyOut', 'moneyIn', 'brandPrimary', 'warning'):
            r = ratio(t[role], t[surf])
            cells.append(f'{role[:9]}={r:4.2f}{"" if r >= 4.5 else "!"}')
        print(f'    on {surf:15} ' + ' '.join(cells))
print('  (! = below 4.5:1. `warning` legitimately fails on the wells — it is a')
print('   page/card colour and is never painted there, so the test scopes it to')
print('   `surface` and `surfaceRaised`.)')
print()

print('===== MODE PARITY: same role, contrast against its own surface =====')
ROLES = ['textPrimary', 'textSecondary', 'textTertiary',
         'brandPrimary', 'moneyOut', 'moneyIn',
         'brandSubtle', 'moneyOutSubtle', 'moneyInSubtle', 'border']
print(f'  {"role":18} {"light":>7} {"dark":>7} {"delta":>8}  verdict')
for k in ROLES:
    rl = ratio(LIGHT[k], LIGHT['surface'])
    rd = ratio(DARK[k], DARK['surface'])
    delta = (rd - rl) / rl * 100.0
    if abs(delta) > 40:
        v = 'MISMATCHED'
    elif abs(delta) > 30:
        v = 'OVER 30%'
    elif abs(delta) > 15:
        v = 'drifts'
    else:
        v = 'matched'
    print(f'  {k:18} {rl:6.2f} {rd:6.2f} {delta:+7.1f}%  {v}')

print()
print('===== the doc\'s own claims (Design.md §2.4) =====')
for claim, fg, bg, said in (('moneyOut on white', '#CC3438', '#FFFFFF', 5.10),
                            ('moneyIn on white', '#1C7340', '#FFFFFF', 6.03)):
    actual = ratio(fg, bg)
    print(f'  {claim:18} claimed {said:.2f}:1  actual {actual:.2f}:1'
          f'{"   <-- DOC IS STALE" if abs(actual - said) > 0.05 else ""}')

if len(sys.argv) > 1 and sys.argv[1] == '--fail':
    """Exit non-zero on any hard failure, so this can gate a commit."""
    bad = []
    for name, t in (('light', LIGHT), ('dark', DARK)):
        for role in TEXT_PAIRS:
            if ratio(t[role], t['surface']) < 4.5:
                bad.append(f'{name} {role} on surface')
        for surf in SURFACES:
            for role in ('textPrimary', 'textSecondary', 'textTertiary',
                         'moneyOut', 'moneyIn', 'brandPrimary'):
                if ratio(t[role], t[surf]) < 4.5:
                    bad.append(f'{name} {role} on {surf}')
        for surf in ('surface', 'surfaceRaised'):
            if ratio(t['warning'], t[surf]) < 4.5:
                bad.append(f'{name} warning on {surf}')
        if ratio(t['surfaceRaised'], t['surface']) < 1.05:
            bad.append(f'{name} card-vs-page < 1.05:1')
    if bad:
        print('\nFAILURES:')
        for b in bad:
            print(f'  {b}')
        raise SystemExit(1)
