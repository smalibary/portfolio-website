import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'data/blog_data.dart';
import 'data/paper_data.dart';
import 'data/site_data.dart';
import 'pages/home.dart';
import 'pages/blog_post.dart';
import 'pages/admin/login.dart';
import 'pages/admin/profile.dart';
import 'pages/admin/blog.dart';
import 'pages/admin/research.dart';

class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) {
    return Document(
      title: 'سالم مليباري — Salem Malibary',
      lang: 'ar',
      meta: const {
        'description':
            'Salem Malibary — PhD candidate at the University of Sydney researching nature, remote work, and cognition. Lecturer at King Abdulaziz University.',
        'theme-color': '#0a0c0e',
      },
      head: [
        link(rel: 'preconnect', href: 'https://fonts.googleapis.com'),
        link(
          rel: 'preconnect',
          href: 'https://fonts.gstatic.com',
          attributes: const {'crossorigin': ''},
        ),
        link(
          rel: 'stylesheet',
          href:
              'https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@300;400;500&family=Inter:wght@300;400;500;600;700&family=IBM+Plex+Sans+Arabic:wght@300;400;500;600;700&display=swap',
        ),
        link(rel: 'stylesheet', href: '/styles.css'),
        link(rel: 'stylesheet', href: '/admin.css'),
        // Apply persisted theme before paint to avoid flash of wrong theme
        script(
          content:
              "(function(){var t=localStorage.getItem('salem-theme');"
              "if(t){document.documentElement.setAttribute('data-theme',t);}"
              "else{document.documentElement.setAttribute('data-theme','dark');}})();",
        ),
      ],
      body: Router(
        routes: [
          Route(
            path: '/',
            builder: (context, state) => HomePage(
              site: SiteData.load(),
              posts: BlogPost.loadAll(),
              papers: Paper.loadAll(),
            ),
          ),
          // One Route per blog post, generated at build time. Static rendering
          // emits an HTML file for each — the homepage links work end-to-end.
          for (final post in BlogPost.loadAll())
            Route(
              path: '/blog/${post.slug}',
              title: '${post.titleAr.isNotEmpty ? post.titleAr : post.titleEn} · Salem Malibary',
              builder: (context, state) => BlogPostPage(
                site: SiteData.load(),
                post: post,
                body: post.loadBody(),
              ),
            ),
          Route(
            path: '/admin/login',
            title: 'الدخول · Admin',
            builder: (context, state) => const AdminLoginPage(),
          ),
          Route(
            path: '/admin/profile',
            title: 'الملف الشخصي · Admin',
            builder: (context, state) => const AdminProfilePage(),
          ),
          Route(
            path: '/admin/blog',
            title: 'المقالات · Admin',
            builder: (context, state) => const AdminBlogPage(),
          ),
          Route(
            path: '/admin/research',
            title: 'الأبحاث · Admin',
            builder: (context, state) => const AdminResearchPage(),
          ),
        ],
      ),
    );
  }
}
