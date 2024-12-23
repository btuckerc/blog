---
title: Setting up a Blog with Obsidian and Hugo
description: A comprehensive guide to setting up a modern blog using Hugo, Obsidian, DigitalOcean, and Bluesky PDS integration.
date: 2024-12-22T16:08:23-05:00
modified: 2024-12-22T16:08:14-05:00
author: Tucker
canonicalURL: "{{ .Site.BaseURL }}{{ .RelPermalink }}"
tags:
  - blog
  - hugo
  - obsidian
  - devops
  - bluesky
categories:
  - blog
  - tutorial
pinned: true
weight: 0
showToc: true
TocOpen: true
draft: false
hidemeta: false
comments: false
searchHidden: false
ShowReadingTime: true
ShowBreadCrumbs: true
ShowPostNavLinks: true
ShowWordCount: true
ShowRssButtonInSectionTermList: true
UseHugoToc: true
ShowEditButton: true
cover:
  image:
  alt: "Blog Setup Overview"
  caption: "Setting up a modern blog with Hugo, Obsidian, and Bluesky"
  relative: true
  hidden: true
editPost:
  URL: https://github.com/btuckerc/blog/content
  Text: Suggest Changes
  appendFilePath: true
---
# The Journey to a Modern Blog

This post outlines how I built a blog that leverages Hugo for static site generation and Obsidian for note-taking. On top of that, I deployed everything to a DigitalOcean droplet and integrated the site with my own Bluesky PDS.

![[2024-12-22-Setting-up-a-Blog-with-Obsidian-and-Hugo-3.png]]

---

## Part 1: Local Setup

### Creating the Hugo Site

To begin, install and configure Hugo on your local machine. Below is an example on macOS using Homebrew:

```bash
# Install Hugo on macOS
brew install hugo

# Create a new Hugo site
hugo new site Blog
cd Blog

# Initialize Git and set main as the default branch
git init
git branch -M main

# Add the Paper theme as a submodule
git submodule add https://github.com/nanxiaobei/hugo-paper themes/paper

# Create basic directory structure
mkdir -p content/Blog-Posts
mkdir -p content/Blog-Attachments
mkdir -p static/images
```

### Setting Up Obsidian Integration

I prefer writing posts in Obsidian. To keep everything in sync, I created symbolic links (`symlinks`) from my local Hugo content directories to my Obsidian vault:

```bash
# Adjust paths to match your own system layout
ln -sf /Users/tucker/Documents/GitHub/Blog/content/Blog-Posts ~/Documents/00-Vault/00\ -\ Inbox/07\ -\ BLOG
ln -sf /Users/tucker/Documents/GitHub/Blog/content/Blog-Attachments ~/Documents/00-Vault/00\ -\ Inbox/07\ -\ BLOG
```

With these symlinks, any changes I make in Obsidian are automatically reflected in my Hugo content folder.

![[2024-12-22-Setting-up-a-Blog-with-Obsidian-and-Hugo-4.png]]

---

## Part 2: Infrastructure Setup

### Creating a DigitalOcean Droplet

To host the site, I use a DigitalOcean droplet. Once you’ve created your droplet, SSH into it to set up the necessary directories:

```bash
# SSH into your new droplet
ssh -i ~/.ssh/btuckerc-do_nok root@DROPLET_IP

# Create a directory for your blog
mkdir -p /opt/blog
```

![[2024-12-22-Setting-up-a-Blog-with-Obsidian-and-Hugo-5.png]]

### Setting Up GitHub Actions

To automate building and deploying, I rely on GitHub Actions. In your repository, create a `.github/workflows` directory with two workflow files.

1. **`build.yml`** for building the site:

    ```yaml
    name: Build and Update Public Branch

    on:
      push:
        branches:
          - main

    permissions:
      contents: write

    jobs:
      build-and-update-public:
        runs-on: ubuntu-latest
        env:
          HUGO_BASEURL: https://btuckerc.com
          HUGO_ENV: production
          HUGO_ENABLEGITINFO: true
        steps:
          - name: Checkout main
            uses: actions/checkout@v4
            with:
              submodules: true
              fetch-depth: 0

          # ... (more steps in the actual file)
    ```

2. **`deploy.yml`** for deploying to DigitalOcean:

    ```yaml
    name: Deploy to DigitalOcean

    on:
      workflow_run:
        workflows: ["Build and Update Public Branch"]
        types:
          - completed
        branches:
          - main

    # ... (more configuration in the actual file)
    ```


![[2024-12-22-Setting-up-a-Blog-with-Obsidian-and-Hugo-6.png]]

---

## Part 3: Bluesky PDS Integration

### Setting Up the PDS Server

I also run my own Bluesky Personal Data Server (PDS). Below is an excerpt from my `docker-compose.yml`:

```yaml
services:
  pds:
    image: ghcr.io/bluesky-social/pds:latest
    restart: unless-stopped
    depends_on:
      - nginx
    environment:
      - PDS_HOSTNAME=${PDS_HOSTNAME}
      - PDS_JWT_SECRET=${PDS_JWT_SECRET}
      # ... more environment variables
```

![[2024-12-22-Setting-up-a-Blog-with-Obsidian-and-Hugo-7.png]]

### Nginx Configuration

To serve both the static blog and the PDS endpoints on the same droplet, I configured Nginx like so:

```nginx
server {
    listen 443 ssl;
    server_name btuckerc.com;

    # Blog content
    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files $uri $uri/ =404;
    }

    # PDS endpoints
    location /.well-known/ {
        proxy_pass http://pds:3000/.well-known/;
        # ... more proxy settings
    }
}
```

---

## Part 4: The Final Touches

### Environment Secrets

In your GitHub repository, set up these secrets to ensure secure deployments and PDS functionality:

- `DROPLET_IP`
- `DROPLET_USER`
- `SSH_PRIVATE_KEY`
- `PDS_HOSTNAME`
- `PDS_JWT_SECRET`
- `PDS_ADMIN_PASSWORD`
- `PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX`

![[2024-12-22-Setting-up-a-Blog-with-Obsidian-and-Hugo-8.png]]

### Automatic Image Processing

For Obsidian-style image links, I wrote a simple script (`migrate_attachments.sh`) to convert them into standard Markdown references and ensure the files end up in the right locations:

```bash
#!/bin/bash
# This script converts Obsidian-style image links to standard markdown
# and ensures images are in the correct locations
# ... (script contents in the repo)
```

---

## Part 5: Customizing Layouts

### Overwriting Theme Files

One of the key aspects of personalizing my blog was implementing custom layouts to overwrite the default files from the theme. This allowed me to tailor the appearance and functionality to better suit my needs. By creating custom layout files in the `layouts` directory, I was able to override the theme's default templates and have my own little touches on format and styling.

![[2024-12-22-Setting-up-a-Blog-with-Obsidian-and-Hugo-9.png]]

---

## Part 6: Search Functionality

### Re-Implementing Search

I had fun re-implementing the search functionality in the `assets` directory. This involved customizing the JavaScript and CSS to enhance the search experience on my blog. I wanted users to be able to query for a word and have the results highlighted, with a few rows of content displayed before and after each result. This made it easier for users to find relevant information quickly and efficiently.

![[2024-12-22-Setting-up-a-Blog-with-Obsidian-and-Hugo-10.png]]

---

## Part 13: Copy/Share and Pinning Features

### Enhancing User Interaction

To improve user interaction, I implemented my own copy/share functionality on blog posts. This allows readers to easily share content with others or save it for later reference. Additionally, I added a pinning feature, enabling users to pin their favorite posts for quick access.

![[2024-12-22-Setting-up-a-Blog-with-Obsidian-and-Hugo-11.png]]
![[2024-12-22-Setting-up-a-Blog-with-Obsidian-and-Hugo-12.png]]

---

## Part 7: DigitalOcean Droplet Management

### Handling Misconfigurations

During the setup, I encountered several misconfigurations that required me to stop and restart the DigitalOcean droplet a lot. Doing it again, it's not the end of the world to destroy the droplets then set them back up. But definitely frustrating.

---

## Part 8: GitHub Secrets Management

### Learning from Mistakes

Managing secrets in GitHub was another challenge. I initially misconfigured some secrets, which led to deployment issues. Thankfully this didn't require destroying and reconfiguring droplets... but still not fun.

---

## Part 9: Integration with Obsidian

### Seamless Content Management

My goal was to have a blog integrated with Obsidian, where I already take notes. This setup allows me to move content over and publish it with ease. Deciding where to store content—between Obsidian sync and GitHub—was initially challenging, but I eventually settled on using both for optimal workflow.

---

## Part 10: DNS/CNAME Configuration

### Connecting Squarespace Domain

Setting the DNS/CNAME entry in my Squarespace domain to point to the DigitalOcean droplet was a crucial step. This configuration ensures that my domain correctly routes traffic to the blog hosted on the droplet, providing a seamless experience for visitors.

![[2024-12-22-Setting-up-a-Blog-with-Obsidian-and-Hugo-13.png]]

---

## Part 11: AT Protocol and Bluesky Handle

### Integrating AT Protocol

I aimed to have the AT Protocol running to register my Bluesky handle while ensuring the frontend was engaging and informative. This integration was crucial for providing a seamless user experience and showcasing the capabilities of the Bluesky PDS.


---

## Part 12: Customizing the Paper Theme

### Why Paper Stood Out

The Paper theme initially caught my attention due to its clean and minimalist design. However, I found it necessary to tweak certain aspects to better align with my blog's aesthetic and functional requirements. These customizations allowed me to maintain the theme's simplicity while adding unique touches.

---

## The Result

Here’s a summary of what this setup achieves:

- **Hugo** for a fast, secure static blog
- **Obsidian** for a modern writing experience
- **GitHub Actions** to automate builds and deployments
- **DigitalOcean** for hosting and SSL
- **Bluesky PDS** for decentralized social features

---

## What's Next?

I plan to extend this setup with:

- A commenting system
- Analytics
- Additional Bluesky integrations

Keep an eye on future posts for these updates!

---

## Useful Resources

- [Hugo Documentation](https://gohugo.io/documentation/)
- [PaperMod Theme](https://github.com/adityatelange/hugo-PaperMod)
- [Bluesky PDS Documentation](https://github.com/bluesky-social/pds)
- [DigitalOcean Tutorials](https://www.digitalocean.com/community/tutorials)

The [repository](https://github.com/btuckerc/Blog) is public if you want to check it out.

---
