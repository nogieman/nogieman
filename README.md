# Personal Portfolio Website

A modern, minimalist portfolio website built with Hugo, featuring a dark theme and responsive design.

## Features

- 📱 Fully responsive design
- ⚡ Fast loading times (Built with Hugo)
- 🎨 Modern minimalist design
- 🔤 Space Grotesk typography
- 🎯 Sections for:
  - About
  - Experience
  - Projects
  - Blog
  - Contact
- ⌚ Real-time local time display
- 🔗 Social media integration

## Tech Stack

- [Hugo](https://gohugo.io/) - Static Site Generator
- [Tailwind CSS](https://tailwindcss.com/) - Styling
- JavaScript - Interactivity
- Go - basic logic
- [Space Grotesk](https://fonts.google.com/specimen/Space+Grotesk) - Typography

## Getting Started

1. **Prerequisites**
   - Install [Hugo](https://gohugo.io/installation/)
   - Install [Git](https://git-scm.com/)

2. **Installation**
   ```bash
   # Clone the repository
   git clone https://github.com/yourusername/hugo-prxshetty.git

   # Navigate to the project directory
   cd hugo-prxshetty

   # Start the Hugo server
   hugo server -D
   ```

3. **Customization**
   - Edit `config.toml` for basic site configuration
   - Modify content in the `content/` directory
   - Customize theme in `themes/prxshetty-minimalistic/`

## Configuration

Update the following in `config.toml`:

```toml
[params]
  name = "Your Name"
  description = "Your Description"
  location = "Your Location"
  email = "your.email@example.com"
  github = "https://github.com/yourusername"
  linkedin = "https://linkedin.com/in/yourusername"
  twitter = "https://twitter.com/yourusername"
```

## Deployment

1. Build the site:
   ```bash
   hugo --minify
   ```

2. Deploy the `public/` directory to your hosting provider

## Contributing

Feel free to submit issues and enhancement requests!

## Contact
For template inquiries or support:
- Email: [prxshetty@gmail.com](mailto:prxshetty@gmail.com)
- Twitter: [@prxshetty](https://twitter.com/prxshetty)

## Adding Company Links to Experience Section

This site supports displaying clickable links for companies in the "Experience" section on both the homepage and the dedicated Experience page.

To add or update these links:

1.  **Update Data Files**:
    *   Navigate to the `data/<language_code>/` directory (e.g., `data/en/`).
    *   Open the `experience.yaml` (or `.json`/`.toml`) file for the desired language.
    *   For each experience entry, you can add a `company_link` field.
        ```yaml
        experience:
          - company: "Example Company Inc."
            company_link: "https://www.example.com" # Add the URL here
            role: "Software Wizard"
            period: "Jan 2023 - Present"
            country: "Remote"
            # ... other fields
          - company: "Another Great Place"
            # company_link: "" # If no link, this can be omitted or left blank
            role: "Lead Developer"
            period: "May 2020 - Dec 2022"
            # ... other fields
        ```
    *   If a `company_link` is provided, the company name will be displayed as a hyperlink. If it's omitted or left empty, the company name will be displayed as plain text.

2.  **Styling**:
    *   The links are styled to match the site's theme.
    *   On the Experience page (`/experience`), company links will appear in the secondary text color (grey) by default and turn to the accent color (blue) on hover.
    *   On the homepage, company links will appear in grey (`text-gray-400`) by default and turn to the accent color (blue) on hover.
    *   An external link icon will automatically appear next to linked company names.

3.  **No Template Changes Needed**:
    *   The layout files (`themes/hugo-noir/layouts/_default/experience.html` and `themes/hugo-noir/layouts/index.html`) have already been configured to handle this feature. You only need to update the data files as described above.

Remember to replace `<language_code>` with the actual language code (e.g., `en`, `es`, `fr`) for each language version of your site you wish to update.

---
Built with ❤️ using Hugo