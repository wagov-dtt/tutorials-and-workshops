# HTML App

Minimal HTML app template with Alpine.js, PicoCSS, and FastAPI. No build tools, no complex abstractions.

## Stack

- **Frontend**: Alpine.js, PicoCSS, RemixIcon
- **Backend**: FastAPI with SRI-verified ES module import maps

## Quick Start

```bash
uv run fastapi dev
```

## Notes

- Uses [esm.sh](https://esm.sh) for ES module CDN by default (drop-in replacements for npm packages with excellent tree-shaking and compression)
- Import map is generated on startup with subresource integrity hashes for security

