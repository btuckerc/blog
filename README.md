# btuckerc Blog

This repository contains my personal blog, built with Hugo using the PaperMod theme.

## Quick Start

```bash
# Run the development server
hugo server -D

# Build static site
hugo
```

## Directory Structure

```
.
├── content/
│   ├── Blog-Posts/     # Blog post markdown files
│   └── Blog-Attachments/ # Images and other attachments
├── static/
│   └── images/         # Site-wide images (profile pic, etc.)
├── themes/             # Hugo themes
└── public/            # Generated static site (not committed)
```

## Common Tasks

### Creating a New Post

1. Create a new markdown file in `content/Blog-Posts/` with the format `YYYY-MM-DD-Title.md`
2. Include the required front matter:
   ```yaml
   ---
   title: "Your Title"
   date: YYYY-MM-DDTHH:mm:ssZ
   tags: ["tag1", "tag2"]
   ---
   ```
3. Write your content in markdown
4. Place any images in `content/Blog-Attachments/` and reference them relatively

### Updating Profile Picture

1. Replace the file at `static/images/profile.jpg`
2. The image is automatically used for:
   - Favicon
   - Site icon
   - Apple touch icon
   - Safari pinned tab

### Managing Images

- Store all post-related images in `content/Blog-Attachments/`
- Use the migration script if needed:
  ```bash
  ./scripts/migrate_attachments.sh
  ```
  This script ensures all images are in the correct location and updates references.

### Deployment

1. Generate the static site:
   ```bash
   ./scripts/build_and_deploy.sh
   ```
   This will:
   - Build the static site
   - Commit changes to the 'public' branch
   - Push changes to GitHub

2. The 'public' branch can then be used for hosting (e.g., GitHub Pages, Netlify, etc.)

## Development

### Local Development

```bash
# Start development server
hugo server -D

# Access the site at http://localhost:1313
```

### Theme Customization

The site uses PaperMod theme with customizations in `hugo.toml`. Main configurations:
- Dark/light mode toggle
- Social links
- Navigation menu
- SEO settings

## Maintenance

### Regular Tasks
1. Keep Hugo updated
2. Check for theme updates
3. Verify all images are properly referenced
4. Ensure content is backed up

### Troubleshooting

If images aren't showing:
1. Run the migration script
2. Check file permissions
3. Verify paths in markdown files

## License

Content is copyrighted. Theme and Hugo are under their respective licenses.
