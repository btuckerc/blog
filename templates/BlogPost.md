<%*
// Prompt for the blog title first
const title = await tp.system.prompt("Enter the blog post title", "");
if (!title) {
    throw new Error("A title is required to create the blog post");
}

// Function to generate overview from title
function generateOverview(title) {
    return `This post explores ${title.charAt(0).toLowerCase() + title.slice(1)}, discussing key concepts and practical applications.`;
}

const overview = generateOverview(title);
const date = tp.date.now("YYYY-MM-DDTHH:mm:ssZ");

// Rename the file to match the title
const newFileName = `${tp.date.now("YYYY-MM-DD")}-${title.replace(/\s+/g, '-')}`;
await tp.file.rename(newFileName);
_%>
---
title: "<% title %>"
description: "<% overview %>"
date: <% date %>
modified: <% tp.file.last_modified_date("YYYY-MM-DDTHH:mm:ssZ") %>
author: "Tucker"
tags:
  - blog
categories:
  - blog
pinned: false
weight: 0
showToc: true
TocOpen: false
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
cover:
    image: "<image path/url>"
    alt: "<alt text>"
    caption: "<text>"
    relative: false
    hidden: true
editPost:
    URL: "https://github.com/btuckerc/blog/content"
    Text: "Suggest Changes"
    appendFilePath: true
---

# Overview
<% overview %>

# Content

[Write your content here. Use ## for main sections and ### for subsections.]


---
