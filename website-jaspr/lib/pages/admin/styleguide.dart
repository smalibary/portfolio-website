import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../../components/admin/admin_shell.dart';

/// Internal design token reference page — /admin/styleguide.
/// Shows every token visually: colours, spacing, radii, typography, components.
class StyleguidePage extends StatelessComponent {
  const StyleguidePage({super.key});

  @override
  Component build(BuildContext context) {
    return AdminShell(
      current: 'styleguide',
      body: [div(classes: 'styleguide', [
        // Inline CSS for the styleguide layout
        script(
          attributes: const {'type': 'text/css'},
          content: _css,
        ),
        main_(classes: 'sg-main', [
          _section('Colours', _colors()),
          _section('Spacing Scale', _spacing()),
          _section('Radius Scale', _radius()),
          _section('Typography', _typography()),
          _section('Components', _components()),
        ]),
      ])],
    );
  }

  Component _section(String title, List<Component> children) {
    return div(classes: 'sg-section', [
      h2(classes: 'sg-h2', [text(title)]),
      div(classes: 'sg-section-body', children),
    ]);
  }

  List<Component> _colors() {
    const tokens = [
      '--bg', '--bg-elev', '--bg-card',
      '--ink', '--ink-muted', '--ink-faint',
      '--rule', '--accent', '--accent-warm', '--accent-cool',
    ];
    return [
      div(classes: 'sg-color-grid', [
        for (final t in tokens)
          div(classes: 'sg-color-item', [
            div(classes: 'sg-swatch', attributes: {'style': 'background:var($t)'}, []),
            span(classes: 'sg-label', [text(t)]),
          ]),
      ]),
    ];
  }

  List<Component> _spacing() {
    const tokens = [
      '--space-0-5', '--space-1', '--space-1-5', '--space-2',
      '--space-2-5', '--space-3', '--space-4', '--space-5',
      '--space-6', '--space-8', '--space-12', '--space-16',
    ];
    return [
      div(classes: 'sg-spacing-list', [
        for (final t in tokens)
          div(classes: 'sg-spacing-row', [
            span(classes: 'sg-bar sg-bar-accent', attributes: {'style': 'width:var($t)'}, []),
            span(classes: 'sg-label', [text('$t → \${} (see actual width)')]),
          ]),
      ]),
    ];
  }

  List<Component> _radius() {
    const tokens = ['--radius-sharp', '--radius-sm', '--radius-md'];
    return [
      div(classes: 'sg-radius-row', [
        for (final t in tokens)
          div(classes: 'sg-radius-box', attributes: {'style': 'border-radius:var($t)'}, [
            span(classes: 'sg-label', [text(t)]),
          ]),
      ]),
    ];
  }

  List<Component> _typography() {
    const tokens = [
      '--text-xs', '--text-sm', '--text-base', '--text-md',
      '--text-lg', '--text-xl', '--text-2xl', '--text-3xl',
    ];
    return [
      div(classes: 'sg-type-list', [
        for (final t in tokens)
          div(classes: 'sg-type-row', [
            span(classes: 'sg-type-sample', attributes: {'style': 'font-size:var($t)'}, [text('Salem سالم')]),
            span(classes: 'sg-label', [text(t)]),
          ]),
      ]),
    ];
  }

  List<Component> _components() {
    return [
      // Card sample
      p([text('Card:')]),
      div(classes: 'sg-comp card', [
        div(classes: 'card__head', [
          span(classes: 'pill pill--published', [text('PUBLISHED')]),
          span(classes: 'card__index', [text('sample_01')]),
        ]),
        div(classes: 'card__metric', [text('g = −0.67')]),
        div(classes: 'card__metric-label', [text('95% CI [−1.16, −0.18] · 16 studies')]),
        div(classes: 'card__title-ar', [text('عنوان تجريبي للمكون')]),
        div(classes: 'card__title-en', [text('Sample component title')]),
      ]),

      // Pills
      p([text('Pills:')]),
      div(classes: 'sg-comp-row', [
        span(classes: 'pill pill--published', [text('PUBLISHED')]),
        span(classes: 'pill pill--active', [text('IN FIELD')]),
        span(classes: 'pill pill--design', [text('IN DESIGN')]),
      ]),

      // Tags
      p([text('Tags:')]),
      div(classes: 'sg-comp-row', [
        a(href: '#', classes: 'tag-pill', [text('#architecture')]),
        a(href: '#', classes: 'tag-pill', [text('#psychology')]),
        a(href: '#', classes: 'tag-pill', [text('#research')]),
      ]),

      // Toggle
      p([text('Theme toggle:')]),
      div(classes: 'theme-toggle', attributes: {'dir': 'ltr'}, [
        button(classes: 'theme-toggle active-sim', [text('dark')]),
        button(classes: 'theme-toggle', [text('light')]),
      ]),

      // Input
      p([text('Input:')]),
      input(classes: 'newsletter__input', attributes: const {
        'type': 'email', 'placeholder': 'email@example.com',
      }),

      // Button
      p([text('Button:')]),
      button(classes: 'newsletter__btn', [text('اشترك · Subscribe')]),

      // Blockquote
      p([text('Blockquote:')]),
      blockquote([text('التسويف ليس مشكلة إدارة وقت — بل هو فشل في تنظيم المشاعر')]),

      // Square motif
      p([text('Square motif:')]),
      div(classes: 'sg-comp-row', [
        span(classes: 'sq-mark', []),
        text(' sq-mark (10px) '),
        span(classes: 'sq-mark--sm', []),
        text(' sq-mark--sm (6px) '),
        span(classes: 'sq-frame sg-inline-frame', [text(' sq-frame ')]),
      ]),
    ];
  }
}

const _css = r'''
.sg-main { padding: 32px; max-width: 900px; margin: 0 auto; direction: ltr; text-align: left; font-family: 'IBM Plex Sans Arabic', sans-serif; }
.sg-section { margin-bottom: 48px; }
.sg-h2 { font-size: 18px; font-weight: 600; margin: 0 0 16px; color: var(--ink); border-bottom: 2px solid var(--accent); padding-bottom: 8px; }
.sg-section-body { }
.sg-label { font-family: 'JetBrains Mono', monospace; font-size: 10px; color: var(--ink-muted); letter-spacing: 0.04em; }
.sg-color-grid { display: flex; flex-wrap: wrap; gap: 12px; }
.sg-color-item { display: flex; flex-direction: column; align-items: center; gap: 6px; }
.sg-swatch { width: 64px; height: 64px; border-radius: var(--radius-sm); border: 1px solid var(--rule); }
.sg-spacing-list { display: flex; flex-direction: column; gap: 8px; }
.sg-spacing-row { display: flex; align-items: center; gap: 12px; }
.sg-bar { height: 12px; background: var(--accent); border-radius: var(--radius-sharp); }
.sg-radius-row { display: flex; flex-wrap: wrap; gap: 24px; }
.sg-radius-box { width: 80px; height: 80px; border: 2px solid var(--accent); background: color-mix(in srgb, var(--accent) 8%, transparent); display: flex; align-items: center; justify-content: center; }
.sg-type-list { display: flex; flex-direction: column; gap: 8px; }
.sg-type-row { display: flex; align-items: baseline; gap: 16px; }
.sg-type-sample { color: var(--ink); }
.sg-comp { margin-bottom: 12px; }
.sg-comp-row { display: flex; align-items: center; flex-wrap: wrap; gap: 8px; margin-bottom: 8px; }
.sg-inline-frame { display: inline-block; padding: 4px 12px; font-size: 12px; }
p { margin: 16px 0 6px; font-size: 13px; color: var(--ink-muted); font-weight: 600; text-transform: uppercase; letter-spacing: 0.06em; }
blockquote { border-inline-start: 3px solid var(--accent); padding: 8px 18px; margin: 8px 0; color: var(--ink-muted); font-size: 14px; }
''';
