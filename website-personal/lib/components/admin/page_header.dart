import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

/// Role: layout
/// The single page-header used at the top of every admin page body, so the
/// header looks identical across Blog / Profile / Research. Eyebrow + title +
/// optional subtitle on one side, an optional action (e.g. "+ New") on the
/// other.
class AdminPageHeader extends StatelessComponent {
  const AdminPageHeader({
    required this.titleAr,
    this.eyebrow,
    this.subtitle,
    this.action,
    super.key,
  });

  final String titleAr;
  final String? eyebrow;
  final String? subtitle;

  /// Optional right-aligned action (e.g. a "+ New" button).
  final Component? action;

  @override
  Component build(BuildContext context) {
    return header(classes: 'page-head', [
      div(classes: 'page-head__text', [
        if (eyebrow != null) div(classes: 'eyebrow', [text(eyebrow!)]),
        h1([text(titleAr)]),
        if (subtitle != null) div(classes: 'en', [text(subtitle!)]),
      ]),
      if (action != null) div(classes: 'page-head__action', [action!]),
    ]);
  }
}
