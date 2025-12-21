# Drupal CMS Performance Testing

Performance testing environment for Drupal CMS with FrankenPHP. Keep it simple, measure what matters.

## Quick Start

```bash
just drupal-setup     # Install Drupal CMS with FrankenPHP
just drupal-loadtest  # Run load test (default: 100 req/s for 30s)
```

## Why FrankenPHP?

Single binary, no nginx/php-fpm dance. Caddy + PHP in one process.

- **Simpler stack**: One config file (Caddyfile) for web server + PHP settings
- **Same config everywhere**: DDEV, Docker, Kubernetes
- **No worker mode yet**: Drupal doesn't call `frankenphp_handle_request()`, so we use classic `php_server`

## Benchmarks

8-core dev machine, DDEV/Docker, Drupal CMS homepage, vegeta load test:

| JIT | Saturates at | Latency (p50) |
|-----|--------------|---------------|
| Off | ~130 req/s | 53ms |
| **On (1255)** | **~180 req/s** | **16ms** |

JIT gives ~40% more headroom before saturation.

## PHP Tuning via Caddyfile

FrankenPHP ignores `.ddev/php/*.ini` files. Configure PHP via `php_ini` directives in the Caddyfile:

```caddyfile
{
    frankenphp {
        # Memory - sized for large sites (100+ modules)
        php_ini memory_limit 1G
        php_ini opcache.memory_consumption 512
        php_ini opcache.interned_strings_buffer 64
        php_ini opcache.max_accelerated_files 130000
        
        # JIT - tracing mode (1255) for web apps
        php_ini opcache.jit 1255
        php_ini opcache.jit_buffer_size 256M
        
        # OPcache - disable revalidation for prod
        php_ini opcache.validate_timestamps 0
        php_ini opcache.enable_file_override 1
        
        # Realpath cache - reduce filesystem calls
        php_ini realpath_cache_size 8192K
        php_ini realpath_cache_ttl 600
    }
}
```

See [`.ddev/Caddyfile.drupal`](.ddev/Caddyfile.drupal) for the full config.

### Key Settings Explained

| Setting | Value | Why |
|---------|-------|-----|
| `opcache.jit` | `1255` | Tracing JIT - best for web apps with hot paths |
| `opcache.jit_buffer_size` | `256M` | JIT code cache - larger = more compiled code kept |
| `opcache.memory_consumption` | `512` | Bytecode cache - fits 100+ modules comfortably |
| `opcache.max_accelerated_files` | `130000` | Max cached scripts - Drupal + contrib needs ~50K+ |
| `opcache.validate_timestamps` | `0` | Skip file stat() calls - files don't change in prod |
| `realpath_cache_size` | `8192K` | Cache resolved paths, reduce syscalls |

### Worker Mode (Not Yet)

Drupal's `index.php` doesn't support FrankenPHP worker mode - it doesn't call `frankenphp_handle_request()`. 
There's [ongoing work](https://www.drupal.org/project/drupal/issues/2218651) to add support. When ready, expect another 2-5x improvement.

## Configuration Files

```
.ddev/
├── config.frankenphp.yaml   # FrankenPHP daemon (custom, no #ddev-generated)
├── Caddyfile.drupal         # PHP + security config (the important one)
└── mysql/performance.cnf    # MariaDB tuning
```

**Important**: Remove `#ddev-generated` from `config.frankenphp.yaml` to prevent the add-on from overwriting your custom Caddyfile path.

## Available Commands

```bash
just drupal-setup     # Full install: DDEV + Drupal CMS + recipes
just drupal-start     # Start DDEV
just drupal-stop      # Stop DDEV
just drupal-login     # Get admin login link
just drupal-loadtest  # Load test (configurable: just drupal-loadtest 200 15s)
just drupal-reset     # Delete everything, start fresh
```

## Load Testing

```bash
# Default: 100 req/s for 30s
just drupal-loadtest

# Custom: 200 req/s for 15s
just drupal-loadtest 200 15s

# Find saturation point
just drupal-loadtest 300 10s
```

Uses [vegeta](https://github.com/tsenart/vegeta) for HTTP load testing.

## Drupal Security (via Caddyfile)

The Caddyfile includes security rules from the [official Drupal Caddyfile](https://git.drupalcode.org/project/drupal/-/blob/11.x/Caddyfile):

- Block `.sql`, `.yml`, `composer.json` access
- Block PHP execution in `/sites/*/files/`
- Block `/vendor/*.php` access
- 1-year cache headers for static assets

## Troubleshooting

### Check if settings are applied

```bash
# Create temp phpinfo (FrankenPHP serves it, not CLI)
echo '<?php phpinfo();' > web/phpinfo.php
curl -s http://drupal-cms-perftest.ddev.site/phpinfo.php | grep opcache.jit
rm web/phpinfo.php
```

### FrankenPHP won't start

Check logs:
```bash
ddev logs -s web | tail -20
```

Common issue: Caddyfile syntax error. Validate with:
```bash
ddev exec frankenphp validate --config /var/www/html/.ddev/Caddyfile.drupal
```

### Settings not applied

`ddev drush php:eval` and `php -i` use CLI, not FrankenPHP. Always test via HTTP request.

## Philosophy

This follows [grug-brained](https://grugbrain.dev) principles:

1. **One config file** - PHP settings in Caddyfile, not scattered `.ini` files
2. **Measure first** - `just drupal-loadtest` before and after changes
3. **Boring tech** - OPcache/JIT are battle-tested, no exotic extensions
4. **WET > DRY** - DDEV and prod Caddyfiles are similar but separate (different ports, paths)

## Resources

- [FrankenPHP Configuration](https://frankenphp.dev/docs/config/)
- [FrankenPHP Performance](https://frankenphp.dev/docs/performance/)
- [Official Drupal Caddyfile](https://git.drupalcode.org/project/drupal/-/blob/11.x/Caddyfile)
- [DDEV FrankenPHP Add-on](https://github.com/ddev/ddev-frankenphp)
- [Drupal Worker Mode Issue](https://www.drupal.org/project/drupal/issues/2218651)
