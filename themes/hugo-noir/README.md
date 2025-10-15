# Dark Noir Theme

A clean, minimalistic theme for Hugo with a focus on readability and simplicity.

![Screenshot](https://raw.githubusercontent.com/prxshetty/hugo-noir/main/images/screenshot.png)

## Features

- Responsive design
- Built with Tailwind CSS
- Clean and minimalist aesthetic
- Fast loading times
- SEO-friendly
- Blog-ready
- Dark mode support


## Installation

### Option 1: Clone Repository

```bash
# From your Hugo site directory
git clone https://github.com/prxshetty/hugo-noir themes/hugo-noir
```

### Option 2: Add as a Git Submodule

```bash
# From your Hugo site directory
git submodule add https://github.com/prxshetty/hugo-noir themes/hugo-noir
```

## Configuration

Add the following to your site's `config.toml` to use this theme:

```toml
theme = "hugo-noir"
```

### Hugo Version

This theme requires:
- Hugo Extended version
- Minimum version: 0.92.0

## Content Structure

The theme expects the following content structure:

```
content/
├── posts/        # Blog posts
│   ├── post1.md
│   └── post2.md
└── pages/        # Static pages
    ├── about.md
    └── contact.md
```

## Front Matter Examples

### Blog Post

```yaml
---
title: "My First Post"
date: 2023-03-15T10:30:00+05:30
draft: false
tags: ["hugo", "web development"]
categories: ["tutorials"]
---
```

### Static Page

```yaml
---
title: "About Me"
date: 2023-03-15T10:30:00+05:30
draft: false
menu: "main"
---
```

## Customization

You can customize the theme by modifying the following files:

- `assets/css/`: Custom CSS files
- `layouts/`: HTML templates
- `static/`: Static assets like images and fonts

## License

This theme is released under the MIT License. See the [LICENSE](https://github.com/prxshetty/hugo-noir/blob/main/LICENSE) file for details.

## Credits

- [Hugo](https://gohugo.io/)
- [Tailwind CSS](https://tailwindcss.com/) 