# Preview Deployment Tracker

## Latest

| Field | Value |
|---|---|
| Branch | `preview` |
| Commit | `3916d2c` |
| URL | https://374ad963.salem-portfolio.pages.dev |
| Status | Active |
| Date | 2026-05-09 |

## Changes in this preview

- Mobile responsive CSS for all public pages (hero, cards, writing list, footer)
- About page wrapper fix (div → Component.fragment)
- Blog post nav overflow fix (width/max-width clamp on post-page/post-layout)
- Research detail BIDI fix (direction: ltr + unicode-bidi: isolate)
- Hide og:image hero on mobile blog posts
- Nav dropdown menu fix (removed overflow-x: hidden from nav)
- Sidebar offset fix (works with or without hero image)
- Removed /tag/* and /category/* routes (redundant with /writing?tag=X)
- Removed category field entirely — tags are the only taxonomy now
- Added quick links section to DEPLOY.md
