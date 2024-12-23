# btuckerc Blog

This repository contains my personal blog, built with Hugo and deployed to DigitalOcean with Bluesky PDS integration.

## Quick Start

```bash
# Clone the repository with submodules
git clone --recursive https://github.com/btuckerc/Blog.git
cd Blog

# Install Hugo (macOS)
brew install hugo

# Run the development server
hugo server -D --environment development

# Build static site (done automatically by GitHub Actions)
hugo --minify --baseURL "https://btuckerc.com" --environment production
```

## Directory Structure

```
.
├── content/
│   ├── Blog-Posts/        # Blog post markdown files
│   └── Blog-Attachments/  # Images and other attachments
├── static/
│   └── images/           # Site-wide images (profile pic, etc.)
├── layouts/              # Custom layout overrides
├── assets/              # CSS and JavaScript files
├── public/              # Generated static site (not committed directly)
└── themes/              # Hugo themes
```

## Common Tasks

### Creating a New Post

1. Create a new markdown file in `content/Blog-Posts/` with the format `YYYY-MM-DD-Title.md`
2. Include the required front matter:
   ```yaml
   ---
   title: "Your Title"
   date: YYYY-MM-DDTHH:mm:ss-0500  # Eastern Time
   tags: ["tag1", "tag2"]
   categories: ["category"]
   ---
   ```
3. Write your content in markdown
4. Place any images in `content/Blog-Attachments/` and reference them using relative paths:
   ```markdown
   ![Alt text](../Blog-Attachments/image.png)
   ```

### Managing Images

- Store all post-related images in `content/Blog-Attachments/`
- The `migrate_attachments.sh` script handles image processing:
  ```bash
  ./scripts/migrate_attachments.sh
  ```
  This script:
  - Converts Obsidian-style image links to standard markdown
  - Ensures images are in the correct locations
  - Updates image references in posts

### Deployment

The site uses GitHub Actions for automated deployment:

1. Push changes to the `main` branch
2. GitHub Actions will:
   - Build the Hugo site
   - Update the `public` branch with the built site
   - Deploy to DigitalOcean
   - Update the Bluesky PDS instance

### Environment Setup

The following environment secrets need to be configured in GitHub:

1. Production Environment Secrets:
   - `DROPLET_IP`: DigitalOcean droplet IP
   - `DROPLET_USER`: SSH user (root)
   - `SSH_PRIVATE_KEY`: SSH key for deployment
   - `PDS_HOSTNAME`: Bluesky PDS hostname
   - `PDS_JWT_SECRET`: JWT secret for PDS
   - `PDS_ADMIN_PASSWORD`: PDS admin password
   - `PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX`: PDS rotation key

## Development

### Local Development

```bash
# Start development server with drafts enabled
hugo server -D --environment development

# Access the site at http://localhost:1313
```

### Theme Customization

The site uses the Paper theme with customizations in `hugo.toml`. Main configurations:
- Dark mode by default
- Social links (GitHub, X, Bluesky)
- Custom navigation menu
- SEO settings
- Search functionality

## Maintenance

### Regular Tasks
1. Keep Hugo updated (`brew upgrade hugo`)
2. Check for theme updates (git submodule)
3. Monitor DigitalOcean droplet health
4. Verify SSL certificate renewal
5. Check Bluesky PDS logs

### Troubleshooting

If images aren't showing:
1. Run `./scripts/migrate_attachments.sh`
2. Check the image paths in markdown files
3. Verify the public/blog-posts/Blog-Attachments directory exists
4. Check nginx configuration and logs

## License

Content is copyrighted. Theme and Hugo are under their respective licenses.
