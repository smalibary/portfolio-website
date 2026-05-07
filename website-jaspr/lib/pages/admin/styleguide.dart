import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../../components/admin/admin_shell.dart';

/// Role: chrome (admin-only)
/// Visual reference for design tokens — colours, spacing, type, radii,
/// borders, shadows, and component samples in both themes.
///
/// KNOWN DRIFT RISK: colour hex strings, spacing px values, and type-scale
/// px values in _spacingTokens/_typeTokens are hardcoded for display, not
/// read from the token files. If primitives.css changes, this page will
/// silently lie. TODO: refactor to read computed values from the cascade.
class StyleguidePage extends StatelessComponent {
  const StyleguidePage({super.key});

  @override
  Component build(BuildContext context) {
    return AdminShell(
      current: 'styleguide',
      body: [
        raw('<style>$_css</style>'),

        // ── Topbar ──
        div(classes: 'topbar', [
          div(classes: 'topbar-l', [
            span(classes: 'section-name', [text('دليل الأنماط')]),
            span(classes: 'section-en', [text('STYLE GUIDE')]),
          ]),
        ]),

        // ── Main content ──
        div(classes: 'main sg-main', [
          // ── Colours ──
          _section('الألوان', 'COLOURS', [
            _colourGroup('Background + Structure', [
              ('--bg', '#0a0c0e → #f6f3ec'),
              ('--bg-elev', '#11151a → #efeae0'),
              ('--bg-card', '#14191f → #ffffff'),
              ('--rule', '#1f262e → #e2dccf'),
            ]),
            _colourGroup('Text', [
              ('--ink', '#e6e8eb → #1a1f24'),
              ('--ink-muted', '#8b95a1 → #5e6973'),
              ('--ink-faint', '#4a525c → #a3acb5'),
            ]),
            _colourGroup('Accent', [
              ('--accent', '#4dd4ac → #006d5e'),
              ('--accent-warm', '#f0a868 → #aa5d20'),
              ('--accent-cool', '#8ab4f8 → #2654a0'),
            ]),
          ]),

          // ── Spacing ──
          _section('المسافات', 'SPACING', [
            div(classes: 'sg-spacing-list', [
              for (final (name, px) in _spacingTokens)
                div(classes: 'sg-spacing-row', [
                  div(
                    classes: 'sg-spacing-bar',
                    attributes: {'style': 'width:${px}px'},
                    [],
                  ),
                  span(classes: 'sg-spacing-name', [text(name)]),
                  span(classes: 'sg-spacing-val', [text('${px}px')]),
                ]),
            ]),
          ]),

          // ── Radius ──
          _section('الزوايا المستديرة', 'RADIUS', [
            div(classes: 'sg-radius-row', [
              _radiusBox('--radius-sharp', '2px — pills, tags, toggles'),
              _radiusBox('--radius-sm', '4px — cards, buttons, images'),
              _radiusBox('--radius-md', '8px — modals, dialogs'),
            ]),
          ]),

          // ── Typography ──
          _section('الخطوط', 'TYPOGRAPHY', [
            div(classes: 'sg-type-list', [
              for (final (token, px, usage) in _typeTokens)
                div(classes: 'sg-type-row', [
                  span(
                    classes: 'sg-type-sample',
                    attributes: {'style': 'font-size:${px}px'},
                    [text('سالم Salem 0123')],
                  ),
                  div(classes: 'sg-type-meta', [
                    span(classes: 'sg-type-token', [text(token)]),
                    span(classes: 'sg-type-usage', [text(usage)]),
                  ]),
                ]),
            ]),
          ]),

          // ── Borders ──
          _section('الحدود', 'BORDERS', [
            div(classes: 'sg-border-row', [
              _borderBox('var(--border-rule)', 'border-rule'),
              _borderBox('var(--border-accent)', 'border-accent'),
              _borderBox(
                'none; border-inline-start: var(--border-bar-w) solid var(--accent)',
                'border-bar',
              ),
            ]),
          ]),

          // ── Shadow ──
          _section('الظل', 'SHADOW', [
            div(
              classes: 'sg-shadow-box',
              attributes: {
                'style':
                    'box-shadow: var(--shadow-card); border-radius: var(--radius-sm);',
              },
              [
                span(classes: 'sg-label', [text('--shadow')]),
              ],
            ),
          ]),

          // ── Components ──
          _section('المكونات', 'COMPONENTS', [
            // Card
            _compLabel('Card'),
            div(classes: 'sg-comp-wrap', [
              div(classes: 'card card--published', [
                div(classes: 'card__head', [
                  span(
                    classes: 'pill pill--published',
                    [text('PUBLISHED')],
                  ),
                  span(classes: 'card__index', [text('sample_01')]),
                ]),
                div(classes: 'card__metric', [text('g = −0.67')]),
                div(classes: 'card__metric-label', [
                  text('95% CI [−1.16, −0.18] · 16 studies'),
                ]),
                div(classes: 'card__title-ar', [
                  text('عنوان تجريبي للمكون'),
                ]),
                div(classes: 'card__title-en', [
                  text('Sample component title'),
                ]),
              ]),
            ]),

            // Pills
            _compLabel('Pills'),
            div(classes: 'sg-comp-row', [
              span(classes: 'pill pill--published', [text('PUBLISHED')]),
              span(classes: 'pill pill--active', [text('IN FIELD')]),
              span(classes: 'pill pill--design', [text('IN DESIGN')]),
            ]),

            // Tags
            _compLabel('Tags'),
            div(classes: 'sg-comp-row', [
              a(href: '#', classes: 'tag-pill', [text('#architecture')]),
              a(href: '#', classes: 'tag-pill', [text('#psychology')]),
              a(href: '#', classes: 'tag-pill', [text('#research')]),
            ]),

            // Theme toggle
            _compLabel('Theme toggle'),
            div(
              classes: 'theme-toggle',
              attributes: {'dir': 'ltr'},
              [
                button(classes: 'active', [text('dark')]),
                button(classes: '', [text('light')]),
              ],
            ),

            // Input + Button
            _compLabel('Input'),
            input(
              classes: 'newsletter__input',
              attributes: const {
                'type': 'email',
                'placeholder': 'email@example.com',
                'dir': 'ltr',
              },
            ),

            _compLabel('Button'),
            button(classes: 'newsletter__btn', [text('اشترك · Subscribe')]),

            // Blockquote
            _compLabel('Blockquote'),
            blockquote([
              text(
                'التسويف ليس مشكلة إدارة وقت — بل هو فشل في تنظيم المشاعر',
              ),
            ]),

            // Square motif
            _compLabel('Square motif'),
            div(classes: 'sg-comp-row sg-motif-row', [
              div(classes: 'sg-motif-item', [
                span(classes: 'sq-mark', []),
                span(classes: 'sg-motif-label', [text('sq-mark (10×10)')]),
              ]),
              div(classes: 'sg-motif-item', [
                span(classes: 'sq-mark--sm', []),
                span(
                  classes: 'sg-motif-label',
                  [text('sq-mark--sm (6×6)')],
                ),
              ]),
              div(classes: 'sg-motif-item', [
                span(
                  classes: 'sq-frame sg-inline-frame',
                  [text('sq-frame')],
                ),
              ]),
              div(classes: 'sg-motif-item sg-motif-bar', [
                div(
                  classes: 'sg-bar-demo sq-bar',
                  attributes: {
                    'style':
                        'width:60px; height:28px; border-radius:var(--radius-sm); border:1px solid var(--color-border-default);',
                  },
                  [],
                ),
                span(classes: 'sg-motif-label', [text('sq-bar (3px right)')]),
              ]),
            ]),

            // Nav monogram square
            _compLabel('Nav monogram square'),
            div(classes: 'sg-comp-row', [
              div(classes: 'nav__monogram-square', [text('S')]),
            ]),
          ]),
        ]),
      ],
    );
  }

  // ── Helpers ──

  Component _section(
    String titleAr,
    String titleEn,
    List<Component> children,
  ) {
    return section(classes: 'sg-section', [
      div(classes: 'sg-section-head', [
        h2([text(titleAr)]),
        span(classes: 'sg-section-en', [text(titleEn)]),
      ]),
      div(classes: 'sg-section-body', children),
    ]);
  }

  Component _colourGroup(
    String groupLabel,
    List<(String, String)> tokens,
  ) {
    return div(classes: 'sg-colour-group', [
      span(classes: 'sg-colour-group-label', [text(groupLabel)]),
      div(classes: 'sg-colour-grid', [
        for (final (token, desc) in tokens)
          div(classes: 'sg-colour-item', [
            div(
              classes: 'sg-swatch',
              attributes: {'style': 'background:var($token)'},
              [],
            ),
            div(classes: 'sg-swatch-info', [
              span(classes: 'sg-swatch-name', [text(token)]),
              span(classes: 'sg-swatch-desc', [text(desc)]),
            ]),
          ]),
      ]),
    ]);
  }

  Component _radiusBox(String token, String desc) {
    return div(classes: 'sg-radius-item', [
      div(
        classes: 'sg-radius-box',
        attributes: {'style': 'border-radius:var($token)'},
        [],
      ),
      span(classes: 'sg-radius-token', [text(token)]),
      span(classes: 'sg-radius-desc', [text(desc)]),
    ]);
  }

  Component _borderBox(String borderStyle, String label) {
    return div(
      classes: 'sg-border-box',
      attributes: {'style': 'border: $borderStyle'},
      [span(classes: 'sg-label', [text(label)])],
    );
  }

  Component _compLabel(String label) {
    return div(classes: 'sg-comp-label', [text(label)]);
  }

  // ── Data ──

  static const _spacingTokens = [
    ('--space-0-5', 2),
    ('--space-1', 4),
    ('--space-1-5', 6),
    ('--space-2', 8),
    ('--space-2-5', 10),
    ('--space-3', 12),
    ('--space-4', 16),
    ('--space-5', 20),
    ('--space-6', 24),
    ('--space-8', 32),
    ('--space-12', 48),
    ('--space-16', 64),
  ];

  static const _typeTokens = [
    ('--text-xs', 10, 'pills, badges, meta'),
    ('--text-sm', 12, 'secondary, inputs, TOC'),
    ('--text-base', 14, 'body text, nav'),
    ('--text-md', 16, 'card titles, sections'),
    ('--text-lg', 18, 'writing list primary'),
    ('--text-xl', 20, 'section headings (h2)'),
    ('--text-2xl', 28, 'page titles (h1)'),
    ('--text-3xl', 34, 'hero metric, display'),
  ];
}

// ── Inline CSS ──

const _css = r'''
/* ── Styleguide layout (namespaced under .adm .sg-) ── */

.adm .sg-main { direction: ltr; text-align: left; }

/* Sections */
.adm .sg-section {
  margin-bottom: 48px;
  padding-bottom: 48px;
  border-bottom: 1px solid var(--color-border-default);
}
.adm .sg-section:last-child { border-bottom: none; }
.adm .sg-section-head {
  display: flex;
  align-items: baseline;
  gap: 12px;
  margin-bottom: 24px;
}
.adm .sg-section-head h2 {
  font-size: 20px;
  font-weight: 600;
  color: var(--ink);
  margin: 0;
}
.adm .sg-section-en {
  font-family: 'JetBrains Mono', monospace;
  font-size: 11px;
  color: var(--ink-muted);
  letter-spacing: 0.08em;
  text-transform: uppercase;
}
.adm .sg-label {
  font-family: 'JetBrains Mono', monospace;
  font-size: 11px;
  color: var(--ink-muted);
  letter-spacing: 0.04em;
}

/* ── Colours ── */
.adm .sg-colour-group { margin-bottom: 20px; }
.adm .sg-colour-group:last-child { margin-bottom: 0; }
.adm .sg-colour-group-label {
  display: block;
  font-family: 'JetBrains Mono', monospace;
  font-size: 10px;
  color: var(--ink-muted);
  letter-spacing: 0.1em;
  text-transform: uppercase;
  margin-bottom: 10px;
}
.adm .sg-colour-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
}
.adm .sg-colour-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 12px;
  background: var(--color-surface-elevated);
  border: 1px solid var(--color-border-default);
  border-radius: var(--radius-sm);
  min-width: 260px;
}
.adm .sg-swatch {
  width: 36px;
  height: 36px;
  border-radius: var(--radius-sm);
  border: 1px solid var(--color-border-default);
  flex-shrink: 0;
  /* Visible outline ensures even near-black colours are distinguishable */
  outline: 1px solid color-mix(in srgb, var(--color-text-faint) 50%, transparent);
  outline-offset: 1px;
}
.adm .sg-swatch-info { display: flex; flex-direction: column; gap: 2px; min-width: 0; }
.adm .sg-swatch-name {
  font-family: 'JetBrains Mono', monospace;
  font-size: 12px;
  color: var(--ink);
  letter-spacing: 0.02em;
}
.adm .sg-swatch-desc {
  font-family: 'JetBrains Mono', monospace;
  font-size: 10px;
  color: var(--ink-muted);
}

/* ── Spacing ── */
.adm .sg-spacing-list {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.adm .sg-spacing-row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 4px 0;
}
.adm .sg-spacing-bar {
  height: 10px;
  background: var(--accent);
  border-radius: var(--radius-sharp);
  flex-shrink: 0;
  opacity: 0.7;
}
.adm .sg-spacing-name {
  font-family: 'JetBrains Mono', monospace;
  font-size: 12px;
  color: var(--ink);
  min-width: 100px;
}
.adm .sg-spacing-val {
  font-family: 'JetBrains Mono', monospace;
  font-size: 11px;
  color: var(--ink-muted);
}

/* ── Radius ── */
.adm .sg-radius-row {
  display: flex;
  flex-wrap: wrap;
  gap: 24px;
}
.adm .sg-radius-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
}
.adm .sg-radius-box {
  width: 80px;
  height: 80px;
  border: 2px solid var(--accent);
  background: color-mix(in srgb, var(--accent) 8%, transparent);
}
.adm .sg-radius-token {
  font-family: 'JetBrains Mono', monospace;
  font-size: 11px;
  color: var(--ink);
  text-align: center;
}
.adm .sg-radius-desc {
  font-family: 'JetBrains Mono', monospace;
  font-size: 10px;
  color: var(--ink-muted);
  text-align: center;
  max-width: 120px;
}

/* ── Typography ── */
.adm .sg-type-list {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.adm .sg-type-row {
  display: flex;
  align-items: baseline;
  gap: 16px;
  padding: 6px 0;
  border-bottom: 1px solid color-mix(in srgb, var(--color-border-default) 50%, transparent);
}
.adm .sg-type-row:last-child { border-bottom: none; }
.adm .sg-type-sample {
  color: var(--ink);
  min-width: 200px;
  white-space: nowrap;
}
.adm .sg-type-meta { display: flex; flex-direction: column; gap: 2px; }
.adm .sg-type-token {
  font-family: 'JetBrains Mono', monospace;
  font-size: 12px;
  color: var(--ink);
}
.adm .sg-type-usage {
  font-family: 'JetBrains Mono', monospace;
  font-size: 10px;
  color: var(--ink-muted);
}

/* ── Borders ── */
.adm .sg-border-row {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
}
.adm .sg-border-box {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 160px;
  height: 64px;
  background: var(--color-surface-elevated);
  border-radius: var(--radius-sm);
}

/* ── Shadow ── */
.adm .sg-shadow-box {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 200px;
  height: 80px;
  background: var(--color-surface-card);
}

/* ── Components ── */
.adm .sg-comp-label {
  font-family: 'JetBrains Mono', monospace;
  font-size: 10px;
  color: var(--ink-muted);
  letter-spacing: 0.1em;
  text-transform: uppercase;
  margin-bottom: 8px;
  margin-top: 20px;
}
.adm .sg-comp-label:first-child { margin-top: 0; }
.adm .sg-comp-wrap {
  max-width: 320px;
  margin-bottom: 12px;
}
.adm .sg-comp-row {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 12px;
}
.adm .sg-inline-frame {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 4px 14px;
  font-size: 12px;
  font-family: 'JetBrains Mono', monospace;
  color: var(--ink-muted);
}
.adm .sg-motif-row { gap: 20px; }
.adm .sg-motif-item {
  display: flex;
  align-items: center;
  gap: 8px;
}
.adm .sg-motif-label {
  font-family: 'JetBrains Mono', monospace;
  font-size: 11px;
  color: var(--ink-muted);
}
.adm .sg-bar-demo { position: relative; }

/* ── Public-site component overrides inside styleguide ──
   The admin CSS has its own .adm .card with rounded corners,
   box-shadow, etc. We need to reset these to the public-site values
   so the styleguide shows components as they actually appear. */

/* Card — reset admin overrides back to public-site styles */
.adm .sg-main .card {
  background: var(--color-surface-card);
  border: 1px solid var(--color-border-default);
  border-radius: var(--radius-sm);
  padding: var(--space-6);
  box-shadow: none;
  min-height: auto;
}
.adm .sg-main .sg-comp-wrap .card {
  cursor: default;
}

/* Theme toggle — public-site version */
.adm .sg-main .theme-toggle {
  display: inline-flex;
  width: fit-content;
  background: var(--color-surface-card);
  border: 1px solid var(--color-border-default);
  border-radius: var(--radius-sharp);
  padding: var(--space-0-5);
  direction: ltr;
}
.adm .sg-main .theme-toggle button {
  background: none;
  border: none;
  cursor: pointer;
  color: var(--ink-muted);
  font-family: 'JetBrains Mono', monospace;
  font-size: var(--text-xs);
  letter-spacing: 0.06em;
  padding: 5px var(--space-2-5);
  border-radius: var(--radius-sharp);
  transition: all 0.2s;
}
.adm .sg-main .theme-toggle button.active {
  background: var(--accent);
  color: var(--color-surface-page); /* TODO(token-semantics): should be --color-interactive-primary-text — see TODO_TOKENS.md */
  font-weight: 500;
}

/* Blockquote — public-site version */
.adm .sg-main blockquote {
  border-inline-start: 3px solid var(--accent);
  padding: 4px 18px;
  margin: 0 0 12px;
  color: var(--ink-muted);
  font-size: 14px;
  line-height: 1.7;
}
''';
