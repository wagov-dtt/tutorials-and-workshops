# Drupal CMS with FrankenPHP

Local Drupal development using [DDEV](https://ddev.com/) and [FrankenPHP](https://frankenphp.dev/).

## Quick Start

```bash
just drupal-setup    # Full install (~3 min)
cd drupal
ddev drush user:login  # Get admin login link
```

Site runs at <https://drupal.ddev.site/>

## Commands

### Just Recipes (Complex Tasks)

| Command | Description |
|---------|-------------|
| `just drupal-setup` | Full install from scratch |
| `just drupal-test` | Run search performance tests |
| `just drupal-reset` | Delete and start fresh (with confirmation) |

### DDEV Commands (Daily Use)

After setup, work directly with DDEV in the `drupal/` directory:

```bash
cd drupal

# Start/stop
ddev start
ddev stop

# Admin access
ddev drush user:login               # Get login link

# Content generation
ddev drush php:script scripts/generate_news_content.php  # 100k articles

# Development
ddev composer require drupal/redis  # Add module
ddev exec drush status              # Run Drush
ddev ssh                            # Shell into container
ddev logs -s web                    # View web logs
```

## What's Included

- **Drupal CMS** - Official starter with sensible defaults
- **FrankenPHP** - Caddy + PHP in one binary (no nginx/php-fpm)
- **MariaDB** - Database with performance tuning
- **DDEV** - Docker-based local dev with SSL

## Project Structure

```
drupal/
├── Caddyfile           # Web server + PHP config
├── Dockerfile          # Production container
├── composer.json       # Drupal dependencies
├── .ddev/              # DDEV configuration
└── kustomize/          # Kubernetes deployment (optional)
```

## Caddyfile

The `Caddyfile` configures Caddy web server and PHP in one place. Shared between DDEV (local) and Docker (production).

### Key Sections

**PHP Settings** - Memory, timeouts, OPcache, JIT:
```caddyfile
frankenphp {
    php_ini memory_limit 1G
    php_ini opcache.jit 1255
}
```

**Security Rules** - Block sensitive files:
```caddyfile
# Hidden files (.git, .env)
@hidden path /.*
error @hidden 403

# PHP in uploads
@dangerousPhp path_regexp ^/sites/[^/]+/files/.*\.php$
error @dangerousPhp 404
```

**Static Caching** - 1 year for assets:
```caddyfile
@static {
    file
    path *.css *.js *.jpg *.png *.woff2
}
header @static Cache-Control "max-age=31536000, public, immutable"
```

### Validation

```bash
just lint                           # Includes Caddyfile check
caddy fmt --diff drupal/Caddyfile   # Manual check
caddy fmt --overwrite drupal/Caddyfile  # Auto-format
```

### Regex Notes

Caddy uses Go regexp:
- `/` is literal (no escaping needed)
- `\.` for literal dots
- `^` and `$` for anchors

## FrankenPHP

Traditional: nginx → php-fpm (2 processes, socket/TCP between them)  
FrankenPHP: Single binary with Caddy + PHP embedded

Benefits:
- Simpler config (one file)
- Faster (no IPC overhead)
- Worker mode for persistent PHP processes

## DDEV Commands

```bash
ddev exec drush status              # Run Drush
ddev composer require drupal/redis  # Add module
ddev ssh                            # Shell into container
ddev logs -s web                    # View web logs
```

## Troubleshooting

**Site won't load:**
```bash
ddev status                # Check if running
ddev logs -s web | tail -20  # View errors
```

**Caddyfile syntax error:**
```bash
caddy fmt --diff drupal/Caddyfile
ddev exec frankenphp validate --config /etc/caddy/Caddyfile
```

**Check PHP settings:**
```bash
# Must test via HTTP (CLI has different php.ini)
echo '<?php phpinfo();' > web/phpinfo.php
open https://drupal.ddev.site/phpinfo.php
rm web/phpinfo.php
```

## Performance

Drupal homepage, 8-core machine:

| JIT | Requests/sec | Response |
|-----|--------------|----------|
| Off | ~130 | 53ms |
| **On** | **~180** | **16ms** |

JIT enabled by default. Run your own test:
```bash
just vegeta https://drupal.ddev.site/
```

## Production Build

```bash
ddev composer install     # Install dependencies first
docker build -t my-drupal .
docker run -p 8080:8080 my-drupal
```

## Resources

- [DDEV Docs](https://ddev.readthedocs.io/)
- [FrankenPHP Docs](https://frankenphp.dev/docs/)
- [Drupal CMS](https://www.drupal.org/about/drupal-cms)
- [Caddy Matchers](https://caddyserver.com/docs/caddyfile/matchers)
