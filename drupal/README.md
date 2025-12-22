# Drupal CMS with FrankenPHP

A local development setup for Drupal CMS using [DDEV](https://ddev.com/) and [FrankenPHP](https://frankenphp.dev/).

## Prerequisites

- [mise](https://mise.jdx.dev/) - run `mise install` in this repo to get DDEV, just, and other tools

## Quick Start

```bash
# Install and start Drupal CMS
just drupal-setup

# Open in browser
just drupal-login
```

Drupal CMS is now running at https://drupal.ddev.site/

## What This Sets Up

- **Drupal CMS** - The official Drupal starter with sensible defaults
- **FrankenPHP** - Modern PHP runtime (Caddy + PHP in one binary)
- **MariaDB** - Database with performance tuning
- **DDEV** - Local development environment

## Common Commands

| Command | What it does |
|---------|--------------|
| `just drupal-setup` | Full install from scratch |
| `just drupal-start` | Start the environment |
| `just drupal-stop` | Stop the environment |
| `just drupal-login` | Get admin login link |
| `just drupal-reset` | Delete everything and start fresh |

## Project Structure

```
drupal/
├── Caddyfile              # Web server + PHP config (used by DDEV and Docker)
├── Dockerfile             # Production container build
├── composer.json          # Drupal dependencies
├── .ddev/                 # DDEV configuration
│   ├── config.yaml        # Main DDEV config
│   └── config.frankenphp.yaml  # FrankenPHP settings
└── kustomize/             # Kubernetes deployment (optional)
```

### Key Files

- **Caddyfile** - One config for web server, PHP settings, and security rules. Used by both local dev (DDEV) and production builds.
- **Dockerfile** - Builds a production container image with FrankenPHP.

## How It Works

### FrankenPHP

Traditional PHP setups use nginx + php-fpm (two processes). FrankenPHP combines Caddy web server with PHP into a single binary - simpler to configure and deploy.

PHP settings are configured directly in the `Caddyfile`:

```caddyfile
{
    frankenphp {
        php_ini memory_limit 1G
        php_ini opcache.jit 1255
    }
}
```

### DDEV

DDEV provides Docker-based local development. It handles:
- SSL certificates (https://drupal.ddev.site)
- Database management
- Composer/Drush commands

FrankenPHP integration is provided by the [ddev-frankenphp](https://github.com/ddev/ddev-frankenphp) addon.

Run commands inside the container with `ddev exec`:
```bash
ddev exec drush status
ddev composer require drupal/module_name
```

## Troubleshooting

### Site won't load

```bash
# Check if DDEV is running
ddev status

# View logs
ddev logs -s web | tail -20
```

### FrankenPHP won't start

Usually a Caddyfile syntax error:
```bash
ddev exec frankenphp validate --config /var/www/html/Caddyfile
```

### Check PHP settings

PHP settings must be tested via HTTP (not CLI):
```bash
echo '<?php phpinfo();' > web/phpinfo.php
open https://drupal.ddev.site/phpinfo.php
rm web/phpinfo.php
```

## Benchmarks

Drupal homepage load test (8-core machine, DDEV):

| PHP JIT | Requests/sec | Response time |
|---------|--------------|---------------|
| Off     | ~130         | 53ms          |
| **On**  | **~180**     | **16ms**      |

JIT (already enabled in this setup) provides ~40% more throughput and 3x faster responses.

*Load tested with [vegeta](https://github.com/tsenart/vegeta).*

### Run your own benchmarks

```bash
just vegeta https://drupal.ddev.site/
```

## Building for Production

The `Dockerfile` creates a production-ready container:

```bash
# Build after running ddev composer install
docker build -t my-drupal .
docker run -p 8080:8080 my-drupal
```

Note: Run `ddev composer install` first - the Dockerfile copies vendor files from the local workspace.

## Resources

- [DDEV Documentation](https://ddev.readthedocs.io/)
- [FrankenPHP Documentation](https://frankenphp.dev/docs/)
- [Drupal CMS](https://www.drupal.org/about/drupal-cms)
- [Official Drupal Caddyfile](https://git.drupalcode.org/issue/drupal-3437187/-/tree/3437187-add-caddyfile-configuration)
