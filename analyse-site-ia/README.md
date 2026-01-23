# Website IA Crawler

A fast, async website crawler that maps information architecture by extracting navigation structures, tracking link relationships, and generating reports.

## Features

- **Fast async crawling** - concurrent requests with configurable parallelism
- **Disk caching** - incremental crawls only fetch new/changed pages (7-day cache)
- **Link analysis** - tracks inbound links to identify hub pages
- **Navigation extraction** - finds nav, sidebar, breadcrumb, and footer links
- **Multiple output formats** - Markdown, CSV, and Excel reports
- **Respects robots.txt** - polite crawling with short timeouts

## Usage

```bash
# Basic crawl (depth 3, max 500 pages)
just analyse-ia https://example.com

# Full site crawl (no page limit)
just analyse-ia-full https://example.com

# Custom settings
just analyse-ia https://example.com 4 1000 15  # depth=4, max=1000, concurrent=15

# Direct script usage
uv run --project analyse-site-ia analyse-site-ia/crawl.py https://example.com

# Disable cache for fresh crawl
uv run --project analyse-site-ia analyse-site-ia/crawl.py https://example.com --no-cache
```

## Output

Reports are saved to `analyse-site-ia/reports/`:

| File | Description |
|------|-------------|
| `{domain}.md` | Markdown report with IA tree, hub pages, nav links |
| `{domain}.csv` | All URLs with metadata (depth, inbound links, etc.) |
| `{domain}.xlsx` | Excel workbook with URLs and Hub Pages sheets |

### Sample Markdown Output

```markdown
# Site IA: example.com

## Statistics
| Metric | Count |
|--------|-------|
| Pages crawled | 488 |
| From cache | 241 |
| Nav links found | 23350 |

## Most Linked Pages
| Links | Path | Title |
|-------|------|-------|
| 485 | `/` | Home |
| 484 | `/about` | About Us |

## Information Architecture
### Products
- **Products**
  - **Category A**
    - **Product 1**
    - **Product 2**
  - **Category B**
```

## How It Works

1. **Fetch robots.txt** - respects crawl rules
2. **Check sitemap** - tries `/sitemap.xml` for URL discovery
3. **BFS crawl** - breadth-first traversal following nav/sidebar links
4. **Extract navigation** - uses CSS selectors to find nav elements
5. **Track links** - counts inbound links to identify important pages
6. **Generate reports** - outputs IA tree and link analysis

## Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| `--depth` | 3 | Maximum link depth to follow |
| `--max-pages` | 500 | Maximum pages to crawl |
| `--concurrency` | 10 | Concurrent HTTP requests |
| `--no-cache` | false | Disable disk cache |

## Rate Limiting

The crawler is designed to be fast but polite:

- **8 second timeout** - fails fast on slow pages
- **50ms batch delay** - small pause between request batches  
- **Googlebot UA** - uses a user agent most sites whitelist
- **No retries** - single attempt per URL

## Caching

HTML responses are cached to `.cache/` for 7 days. This enables:

- **Fast incremental crawls** - only fetch new pages
- **Re-run analysis** - regenerate reports without re-crawling
- **Development** - iterate on reports without hitting the server

Clear cache with: `rm -rf analyse-site-ia/.cache`

## CSS Selectors

The crawler looks for navigation in these elements:

```python
SELECTORS = {
    "nav": ["nav a", "[role='navigation'] a", "header a", ".nav a", ".menu a"],
    "sidebar": [".sidebar a", "aside a", ".submenu a", ".section-nav a"],
    "breadcrumb": [".breadcrumb a", "[aria-label='breadcrumb'] a"],
    "footer": ["footer a", ".footer a"],
}
```

## Dependencies

- `aiohttp` - async HTTP client
- `selectolax` - fast HTML parser
- `diskcache` - disk-based caching
- `openpyxl` - Excel file generation
