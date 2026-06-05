# Contributing to the Drupal example

This directory is a Composer-managed Drupal CMS site for local DDEV experiments. General repo contribution rules live in [../CONTRIBUTING.md](../CONTRIBUTING.md).

## Local setup

Install [DDEV](https://ddev.com/get-started/) 1.25.0 or later, then run:

```bash
cd drupal-hugo
ddev start
ddev launch
```

Useful commands:

```bash
ddev composer install
ddev drush status
ddev drush user:login
ddev drush cache:rebuild
```

## Dependency changes

- Use `ddev composer require ...` or `ddev composer update ...` only when the dependency change is intentional.
- Commit `composer.json` and `composer.lock` together.
- Do not commit `vendor/`.

## Drupal changes

- Put custom modules in `web/modules/custom`.
- Put custom themes in `web/themes/custom`.
- Do not patch Drupal core or contributed projects in place.
- Export/import config with Drush when the lab starts tracking site config.

## Upstream Drupal CMS

Drupal CMS itself is developed at <https://www.drupal.org/project/drupal_cms>. Use the [Drupal CMS issue queue](https://www.drupal.org/project/issues/drupal_cms) for upstream issues.

References:

- [DDEV docs](https://docs.ddev.com/en/stable/)
- [Drupal contribution guide](https://www.drupal.org/contribute)
- [Drupal code of conduct](https://www.drupal.org/dcoc)
