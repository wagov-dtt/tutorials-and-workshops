# HTML App

Minimal HTML app template with Alpine.js, PicoCSS, and FastAPI. No build tools, no complex abstractions.

## Stack

- **Frontend**: Alpine.js, PicoCSS, RemixIcon
- **Backend**: FastAPI with SRI-verified ES module import maps

## Quick Start

```bash
uv run fastapi dev
```

## Philosophy

- **More HTML, less JavaScript.** Templates and logic live in HTML with Alpine directives. JS handles state and data transformations only.
- **More Semantic HTML, less CSS.** Semantic tags (`<aside>`, `<nav>`, `<article>`, etc.) and Pico CSS variables eliminate the need for custom styling.

## Notes

- Uses [esm.sh](https://esm.sh) for ES module CDN by default (drop-in replacements for npm packages with excellent tree-shaking and compression)
- Import map is generated on startup with subresource integrity hashes for security
- CSS is kept minimal—Pico CSS variables handle most styling

