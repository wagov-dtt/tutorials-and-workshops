# PicoChat - HTMX 4.0 App

A modern messaging app UI built with HTMX 4.0 and Pico CSS, featuring dynamic fragment loading.

## Running the App

Use Python's built-in HTTP server:

```bash
cd html-app
python3 -m http.server 8000
```

Then open `http://localhost:8000` in your browser.

## Architecture

- **index.html**: Main page with HTMX attributes for dynamic fragment loading
- **fragments/**: Separate HTML files for each section
  - `dashboard.html` - User profile and recent messages
  - `messages.html` - Message list
  - `contacts.html` - Contact cards
  - `files.html` - File management
  - `settings.html` - Preferences and account settings

## How It Works

Navigation links use HTMX to load fragments dynamically:

```html
<a hx-get="/fragments/dashboard" hx-target="#content">Dashboard</a>
```

When clicked, HTMX requests the fragment and replaces the content section without a full page reload.

## Styling

Built with [Pico CSS](https://picocss.com/) for minimal, semantic styling.
