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
      body: [
        header(classes: 'topbar', [
          div(classes: 'topbar-l', [
            span(style: {'font-size': 'var(--text-sm)', 'opacity': '0.6', 'font-family': 'JetBrains Mono, monospace', 'letter-spacing': '0.08em'}, [
              text('ADMIN · STYLE GUIDE'),
            ]),
          ]),
          div(classes: 'topbar-r', []),
        ]),

        main_(classes: 'main', style: {'padding': '32px', 'max-width': '900px'}, [
          _section('1. Colour Tokens', _colourSection()),
          _section('2. Spacing Scale', _spacingSection()),
          _section('3. Radius Scale', _radiusSection()),
          _section('4. Typography Scale', _typographySection()),
          _section('5. Components', _componentsSection()),
        ]),
      ],
    );
  }

  // ---------- layout helpers ----------

  Component _section(String title, Component content) {
    return div(style: {'margin-bottom': '56px'}, [
      h2(style: {
        'font-family': 'JetBrains Mono, monospace',
        'font-size': 'var(--text-sm)',
        'letter-spacing': '0.08em',
        'color': 'var(--accent)',
        'margin-bottom': '20px',
        'padding-bottom': '8px',
        'border-bottom': '1px solid var(--rule)',
      }, [text(title)]),
      content,
    ]);
  }

  Component _label(String text_) {
    return span(style: {
      'font-family': 'JetBrains Mono, monospace',
      'font-size': '10px',
      'color': 'var(--ink-muted)',
      'display': 'block',
      'margin-top': '6px',
    }, [text(text_)]);
  }

  // ---------- 1. Colours ----------

  Component _colourSection() {
    const tokens = [
      ('--accent', 'accent'),
      ('--bg', 'bg'),
      ('--bg-elev', 'bg-elev'),
      ('--bg-card', 'bg-card'),
      ('--ink', 'ink'),
      ('--ink-muted', 'ink-muted'),
      ('--ink-faint', 'ink-faint'),
      ('--rule', 'rule'),
    ];

    return div(style: {'display': 'flex', 'flex-wrap': 'wrap', 'gap': '16px'}, [
      for (final (token, name) in tokens)
        div(style: {'text-align': 'center'}, [
          div(style: {
            'width': '48px',
            'height': '48px',
            'background': 'var($token)',
            'border': '1px solid var(--rule)',
            'border-radius': 'var(--radius-sharp)',
          }, []),
          _label(name),
          _label(token),
        ]),
    ]);
  }

  // ---------- 2. Spacing ----------

  Component _spacingSection() {
    const tokens = [
      ('--space-0-5', '2px'),
      ('--space-1', '4px'),
      ('--space-1-5', '6px'),
      ('--space-2', '8px'),
      ('--space-2-5', '10px'),
      ('--space-3', '12px'),
      ('--space-4', '16px'),
      ('--space-5', '20px'),
      ('--space-6', '24px'),
      ('--space-8', '32px'),
      ('--space-12', '48px'),
      ('--space-16', '64px'),
    ];

    return div(style: {'display': 'flex', 'flex-direction': 'column', 'gap': '10px'}, [
      for (final (token, px) in tokens)
        div(style: {'display': 'flex', 'align-items': 'center', 'gap': '12px'}, [
          div(style: {
            'height': 'var($token)',
            'width': '120px',
            'background': 'var(--accent)',
            'display': 'block',
            'flex-shrink': '0',
          }, []),
          span(style: {
            'font-family': 'JetBrains Mono, monospace',
            'font-size': '11px',
            'color': 'var(--ink-muted)',
          }, [text('$token  ·  $px')]),
        ]),
    ]);
  }

  // ---------- 3. Radius ----------

  Component _radiusSection() {
    const tokens = [
      ('--radius-sharp', '2px'),
      ('--radius-sm', '4px'),
      ('--radius-md', '8px'),
    ];

    return div(style: {'display': 'flex', 'flex-wrap': 'wrap', 'gap': '24px'}, [
      for (final (token, px) in tokens)
        div(style: {'text-align': 'center'}, [
          div(style: {
            'width': '64px',
            'height': '32px',
            'border': '2px solid var(--accent)',
            'border-radius': 'var($token)',
          }, []),
          _label(token),
          _label(px),
        ]),
    ]);
  }

  // ---------- 4. Typography ----------

  Component _typographySection() {
    const tokens = [
      ('--text-xs', '10px'),
      ('--text-sm', '12px'),
      ('--text-base', '14px'),
      ('--text-md', '16px'),
      ('--text-lg', '18px'),
      ('--text-xl', '20px'),
      ('--text-2xl', '28px'),
      ('--text-3xl', '34px'),
    ];

    return div(style: {'display': 'flex', 'flex-direction': 'column', 'gap': '12px'}, [
      for (final (token, px) in tokens)
        div(style: {'display': 'flex', 'align-items': 'baseline', 'gap': '16px'}, [
          span(style: {
            'font-size': 'var($token)',
            'color': 'var(--ink)',
            'min-width': '60px',
          }, [text('Aa أأ')]),
          span(style: {
            'font-family': 'JetBrains Mono, monospace',
            'font-size': '11px',
            'color': 'var(--ink-muted)',
          }, [text('$token  ·  $px')]),
        ]),
    ]);
  }

  // ---------- 5. Components ----------

  Component _componentsSection() {
    return div(style: {'display': 'flex', 'flex-direction': 'column', 'gap': '32px'}, [
      _componentRow('pill', [
        span(classes: 'pill pill--published', [text('PUBLISHED')]),
        span(style: {'width': '8px'}, []),
        span(classes: 'pill pill--active', [text('ACTIVE')]),
        span(style: {'width': '8px'}, []),
        span(classes: 'pill pill--design', [text('DESIGN')]),
      ]),

      _componentRow('tag-pill', [
        span(classes: 'tag-pill', [text('research')]),
        span(style: {'width': '8px'}, []),
        span(classes: 'tag-pill tag-pill--header', [text('IEQ')]),
      ]),

      _componentRow('sq-mark / sq-mark--sm', [
        div(classes: 'sq-mark', []),
        span(style: {'width': '12px'}, []),
        div(classes: 'sq-mark sq-mark--sm', []),
      ]),

      _componentRow('card', [
        a(
          href: '#',
          classes: 'card card--published',
          [
            div(classes: 'card__head', [
              span(classes: 'pill pill--published', [text('PUBLISHED')]),
              span(classes: 'card__index', [text('01')]),
            ]),
            div(classes: 'card__title-ar', [text('عنوان المقال')]),
            div(classes: 'card__title-en', [text('Article Title Example')]),
            div(classes: 'card__caption', [text('2 min · 400 words')]),
          ],
        ),
      ]),

      _componentRow('pinned-badge', [
        div(classes: 'pinned-badge', [text('PINNED')]),
      ]),
    ]);
  }

  Component _componentRow(String name, List<Component> children) {
    return div(style: {'display': 'flex', 'flex-direction': 'column', 'gap': '8px'}, [
      span(style: {
        'font-family': 'JetBrains Mono, monospace',
        'font-size': '11px',
        'color': 'var(--ink-faint)',
        'letter-spacing': '0.04em',
      }, [text('.$name')]),
      div(style: {'display': 'flex', 'align-items': 'center', 'flex-wrap': 'wrap', 'gap': '8px'}, children),
    ]);
  }
}
