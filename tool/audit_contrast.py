"""Contrast audit for ledgerly's semantic colour tokens (WCAG 2.1)."""


def lin(c: int) -> float:
    s = c / 255.0
    return s / 12.92 if s <= 0.03928 else ((s + 0.055) / 1.055) ** 2.4


def lum(hexstr: str) -> float:
    h = hexstr.lstrip('#')
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)


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


LIGHT = {
    'surface': '#FFFFFF',
    'surfaceRaised': '#FFFFFF',
    'surfaceSubtle': '#F5F7FA',
    'surfaceSunken': '#EDF0F5',
    'border': '#E4E8EE',
    'textPrimary': '#0F1720',
    'textSecondary': '#5A6675',
    'textTertiary': '#98A2B0',
    'textOnBrand': '#FFFFFF',
    'brandPrimary': '#0E7C66',
    'brandSubtle': '#D6F0E8',
    'moneyOut': '#CC3438',
    'moneyOutSubtle': '#FDE7E7',
    'moneyIn': '#1E7A45',
    'moneyInSubtle': '#E3F6E9',
    'warning': '#C98A0B',
}

DARK = {
    'surface': '#0E1218',
    'surfaceRaised': '#182029',
    'surfaceSubtle': '#141A21',
    'surfaceSunken': '#0A0E13',
    'border': '#26313D',
    'textPrimary': '#F5F7FA',
    'textSecondary': '#98A2B0',
    'textTertiary': '#5A6675',
    'textOnBrand': '#06231D',
    'brandPrimary': '#2BB99A',
    'brandSubtle': '#0F2E28',
    'moneyOut': '#FF6B6F',
    'moneyOutSubtle': '#33191B',
    'moneyIn': '#4CC777',
    'moneyInSubtle': '#122C1C',
    'warning': '#E0A63C',
}

TEXT_PAIRS = ['textPrimary', 'textSecondary', 'textTertiary']
MARK_PAIRS = ['brandSubtle', 'moneyOutSubtle', 'moneyInSubtle',
              'moneyOut', 'moneyIn', 'brandPrimary', 'border']


def report(name: str, t: dict) -> None:
    print(f'===== {name} (surface {t["surface"]}) =====')
    print('-- text on surface (AA small text needs 4.5, AA large/UI 3.0) --')
    for k in TEXT_PAIRS:
        r = ratio(t[k], t['surface'])
        flag = 'FAIL' if r < 4.5 else ('large-only' if r < 7 else 'OK')
        print(f'  {k:16} {t[k]}  {r:5.2f}:1  {flag}')
    print('-- marks/fills on surface (a visible non-text mark needs 3.0) --')
    for k in MARK_PAIRS:
        r = ratio(t[k], t['surface'])
        flag = 'FAIL' if r < 3.0 else 'OK'
        print(f'  {k:16} {t[k]}  {r:5.2f}:1  {flag}')
    print('-- text on its own brand fill --')
    print(f'  textOnBrand on brandPrimary: '
          f'{ratio(t["textOnBrand"], t["brandPrimary"]):5.2f}:1')
    print('-- capsule ramp: step 1..4 = lerp(subtle -> full, 0..1) vs surface --')
    for fam, subtle, full in (('expense', 'moneyOutSubtle', 'moneyOut'),
                              ('income', 'moneyInSubtle', 'moneyIn')):
        for step in (1, 2, 3, 4):
            t_ = (step - 1) / 3
            c = lerp(t[subtle], t[full], t_)
            r = ratio(c, t['surface'])
            flag = 'INVISIBLE' if r < 1.6 else ('FAIL' if r < 3.0 else 'OK')
            print(f'  {fam:8} step {step}  {c}  {r:5.2f}:1  {flag}')
    print()


report('LIGHT', LIGHT)
report('DARK', DARK)

print('===== cross-mode: how far apart are the same roles? =====')
for k in ['surface', 'surfaceRaised', 'surfaceSubtle', 'textPrimary',
          'textSecondary', 'textTertiary', 'brandPrimary', 'brandSubtle',
          'moneyOut', 'moneyOutSubtle', 'moneyIn', 'moneyInSubtle']:
    print(f'  {k:16} light {LIGHT[k]}  dark {DARK[k]}')

print()
print('===== the doc\'s own claims (Design.md §2.1) =====')
for claim, fg, bg, said in (('moneyOut on white', '#CC3438', '#FFFFFF', 5.1),
                            ('moneyIn on white', '#1E7A45', '#FFFFFF', 5.35)):
    print(f'  {claim:18} claimed {said}:1  actual {ratio(fg, bg):.2f}:1')

print()
print('===== dark state fills vs dark surface, as a lightness delta =====')
for k in ['brandSubtle', 'moneyOutSubtle', 'moneyInSubtle']:
    print(f'  {k:16} {DARK[k]} lum {lum(DARK[k]):.5f} vs surface '
          f'{lum(DARK["surface"]):.5f}')

# ---------------------------------------------------------------------------
# The pairs the first pass never measured — these are the reported defects.
# ---------------------------------------------------------------------------
print()
print('===== DEFECT PAIRS: foreground painted on its own fill =====')
DEFECT_PAIRS = [
    # (label, fg, bg, light?, note)
    ('selected day digit on its fill', 'brandPrimary', 'brandSubtle'),
    ('FAB glyph on M3 default fill', 'textOnBrand', 'brandSubtle'),
]
for label, fg, bg in DEFECT_PAIRS:
    for name, t in (('light', LIGHT), ('dark', DARK)):
        r = ratio(t[fg], t[bg])
        flag = 'FAIL' if r < 3.0 else 'OK'
        print(f'  {label:32} {name:5} {t[fg]} on {t[bg]}  {r:5.2f}:1  {flag}')

print()
print('===== text on raised surface (cards live here) =====')
for name, t in (('light', LIGHT), ('dark', DARK)):
    for k in ('textPrimary', 'textSecondary', 'textTertiary'):
        r = ratio(t[k], t['surfaceRaised'])
        flag = 'FAIL' if r < 4.5 else ('large-only' if r < 7 else 'OK')
        print(f'  {name:5} {k:16} on surfaceRaised {r:5.2f}:1  {flag}')

print()
print('===== MODE PARITY: same role, contrast against its own surface =====')
print('  A role that reads 5.85 in light and 7.27 in dark is a 24% jump —')
print('  that asymmetry is the measurable form of "the difference is extreme".')
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
    elif abs(delta) > 15:
        v = 'drifts'
    else:
        v = 'matched'
    print(f'  {k:18} {rl:6.2f} {rd:6.2f} {delta:+7.1f}%  {v}')


def lstar(hexstr: str) -> float:
    y = lum(hexstr)
    return 116.0 * (y ** (1 / 3)) - 16 if y > 0.008856 else 903.3 * y


print()
print('===== SURFACE LIGHTNESS (CIE L*): the app\'s overall "tone" =====')
for name, t in (('light', LIGHT), ('dark', DARK)):
    print(f'  {name:5}  ' + '  '.join(
        f'{k}={lstar(t[k]):5.1f}' for k in
        ('surface', 'surfaceRaised', 'surfaceSubtle', 'surfaceSunken')))
print('  dark surfaces span L* '
      f'{lstar(DARK["surfaceSunken"]):.1f}-{lstar(DARK["surfaceRaised"]):.1f} '
      f'({lstar(DARK["surfaceRaised"]) - lstar(DARK["surfaceSunken"]):.1f} pts); '
      'light surfaces span '
      f'{lstar(LIGHT["surfaceSunken"]):.1f}-{lstar(LIGHT["surface"]):.1f} '
      f'({lstar(LIGHT["surface"]) - lstar(LIGHT["surfaceSunken"]):.1f} pts)')
print('  -> dark elevation is legible only if the steps are >=~2 L* apart;')
print('     light relies on shadow instead, so the steps can be tighter.')
