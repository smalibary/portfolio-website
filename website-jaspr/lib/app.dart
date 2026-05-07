import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'data/blog_data.dart';
import 'data/paper_data.dart';
import 'data/site_data.dart';
import 'pages/home.dart';
import 'pages/blog_post.dart';
import 'pages/writing.dart';
import 'pages/research_detail.dart';
import 'pages/tag.dart';
import 'pages/category.dart';
import 'pages/admin/login.dart';
import 'pages/admin/profile.dart';
import 'pages/admin/blog.dart';
import 'pages/admin/research.dart';
import 'pages/admin/styleguide.dart';

class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) {
    // Loaded once per build; SSG enumerates routes statically, so calling
    // these here is safe — they read files synchronously and the data
    // doesn't change mid-render.
    final site = SiteData.load();
    final posts = BlogPost.loadAll();
    final papers = Paper.loadAll();
    final tags = BlogPost.uniqueTags(posts);
    final categories = BlogPost.uniqueCategories(posts);

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
              site: site,
              posts: posts,
              papers: papers,
            ),
          ),
          // Blog post archive at /writing.
          Route(
            path: '/writing',
            title: 'الكتابة · Writing · Salem Malibary',
            builder: (context, state) => WritingPage(site: site, posts: posts),
          ),
          // One Route per blog post, generated at build time.
          for (final post in posts)
            Route(
              path: '/blog/${post.slug}',
              title: '${post.titleAr.isNotEmpty ? post.titleAr : post.titleEn} · Salem Malibary',
              builder: (context, state) => BlogPostPage(
                site: site,
                post: post,
                body: post.loadBody(),
              ),
            ),
          // One Route per research paper.
          for (final paper in papers)
            Route(
              path: '/research/${paper.id}',
              title: '${paper.titleAr.isNotEmpty ? paper.titleAr : paper.titleEn} · Research · Salem Malibary',
              builder: (context, state) => ResearchDetailPage(site: site, paper: paper),
            ),
          // One Route per tag, listing every post that carries it.
          for (final tag in tags)
            Route(
              path: '/tag/$tag',
              title: '#$tag · Salem Malibary',
              builder: (context, state) => TagPage(
                site: site,
                tag: tag,
                posts: posts.where((p) => p.tags.contains(tag)).toList(),
              ),
            ),
          // One Route per category.
          for (final cat in categories)
            Route(
              path: '/category/$cat',
              title: '$cat · Salem Malibary',
              builder: (context, state) => CategoryPage(
                site: site,
                category: cat,
                posts: posts.where((p) => p.category == cat).toList(),
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
          Route(
            path: '/admin/styleguide',
            title: 'Style Guide · Admin',
            builder: (context, state) => const StyleguidePage(),
          ),
        ],
      ),
    );
  }
}
