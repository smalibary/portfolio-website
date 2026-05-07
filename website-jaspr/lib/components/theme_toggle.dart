import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

/// Role: atom
/// Side-effecting: pair of icon buttons that switch document data-theme
/// via inline JS. No Dart hydration, keeps the client bundle small.
class ThemeToggle extends StatelessComponent {
  const ThemeToggle({super.key});

  static const _script = '''
(function(){
  var btns = document.querySelectorAll('[data-theme-set]');
  var current = document.documentElement.getAttribute('data-theme') || 'dark';
  function apply(t){
    document.documentElement.setAttribute('data-theme', t);
    localStorage.setItem('salem-theme', t);
    btns.forEach(function(b){
      b.classList.toggle('active', b.getAttribute('data-theme-set') === t);
    });
  }
  apply(current);
  btns.forEach(function(b){
    b.addEventListener('click', function(){ apply(b.getAttribute('data-theme-set')); });
  });
})();
''';

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      div(classes: 'theme-toggle', [
        button(attributes: const {'data-theme-set': 'dark'}, [text('dark')]),
        button(attributes: const {'data-theme-set': 'light'}, [text('light')]),
      ]),
      script(content: _script),
    ]);
  }
}
