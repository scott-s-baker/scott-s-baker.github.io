# Scott Baker — Portfolio

A personal portfolio site for a senior marketing executive (CMO / VP Product Marketing / VP Marketing / VP Strategy), showcasing writing & thought leadership, published work & patents, videos & talks, and code samples. Built as a static site for **GitHub Pages** — no build step, no dependencies.

---

## 🚀 Publish it (one-time setup, ~5 minutes)

**Option A — user site at `scottbaker.github.io` (recommended, cleanest URL):**

1. Create a GitHub account if you don't have one (use a professional username, e.g. `scott-s-baker`).
2. Create a **new public repository** named **exactly** `<yourusername>.github.io` (e.g. `scott-s-baker.github.io`).
3. Upload the contents of this folder (the `index.html`, the folders, everything) to that repo — drag-and-drop in the browser works fine.
4. Go to **Settings → Pages**. Under "Build and deployment," set Source = **Deploy from a branch**, Branch = **main**, folder = **/ (root)**. Save.
5. Wait 1–2 minutes, then visit **https://<yourusername>.github.io**. Done.

**Option B — project site (if you'd rather keep your username site for something else):**

1. Create a public repo named `portfolio` (or anything).
2. Upload these files.
3. Settings → Pages → deploy from `main` / root.
4. Your site lives at `https://<yourusername>.github.io/portfolio/`.

> Tip: You can later point a custom domain (e.g. `scottbaker.com`) at the site from Settings → Pages → Custom domain.

---

## ✏️ Customize it

Everything lives in **`index.html`** — open it in any text editor. Look for the yellow "EDIT" note boxes on the live page; each maps to a spot in the HTML.

| What | Where in `index.html` |
|---|---|
| Résumé download | Put your PDF at `assets/Scott_Baker_Resume.pdf` (or edit the link) |
| Headline & pitch | The `<header class="hero">` block |
| Metric strip | The `.metrics` block — swap in your best numbers |
| About text | The `#about` section |
| Cards (each section) | Duplicate a `<div class="card">…</div>` to add items; edit the `href` to link the real piece |
| Colors | The `:root` variables at the top of the `<style>` block (brand navy `#1F3864`, accent `#2E75B6` — matched to your résumé) |

Remove the yellow `.hidden-note` boxes once you've added real content (delete those `<div class="hidden-note">…</div>` lines).

---

## 📁 Structure

```
/
├── index.html          ← the site (edit this)
├── assets/             ← résumé PDF, headshot, images
├── writing/            ← articles & thought-leadership (Markdown or links)
├── publications/       ← book, patents, technical references
├── talks/              ← talk descriptions + video links
└── code/               ← code samples / project write-ups
```

Each content folder has its own README explaining what to put there and how to link it from the homepage.

---

## ✅ Recruiter-optimized by design

- **Value proposition in the first screen** — title, pitch, and top metrics before any scroll.
- **Skimmable** — clear sections, cards, and a sticky nav.
- **One-click résumé + LinkedIn + email** in the hero and footer.
- **SEO basics** — descriptive `<title>` and meta description so your name is searchable.
- **Fast & dependency-free** — loads instantly, nothing to maintain or break.
