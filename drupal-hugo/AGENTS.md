# Agent guidance for this Drupal site

This is a Composer-managed Drupal CMS site. Local development uses DDEV. Keep changes reproducible and avoid editing generated/vendor code.

## Local environment

Run commands from `drupal-hugo/` unless the top-level `just drupal::...` wrapper is more convenient.

```bash
ddev start
ddev launch
ddev composer install
ddev drush status
ddev drush user:login
ddev drush cache:rebuild
```

DDEV project config lives in `.ddev/config.yaml`. Use `.ddev/config.local.yaml` for machine-specific overrides; do not commit it.

## Common workflows

Add a module intentionally:

```bash
ddev composer require drupal/<project>
ddev drush pm:enable --yes <module_machine_name>
ddev drush cache:rebuild
```

Apply and manage config:

```bash
ddev drush update:db --yes
ddev drush config:import --yes
ddev drush config:export --yes
```

Commit dependency changes as `composer.json` plus `composer.lock`.

## Guardrails

- Do not commit secrets or machine-local overrides such as `.env`, `settings.local.php`, or `.ddev/config.local.yaml`.
- Do not commit `vendor/` or uploaded files under `web/sites/*/files`.
- Do not edit Drupal core or contributed projects in place.
- Put custom code in `web/modules/custom` and `web/themes/custom`.
- Prefer `composer install` for setup; use `composer update` only for intentional upgrades.

## References

- [DDEV docs](https://docs.ddev.com/en/stable/)
- [Drush docs](https://www.drush.org/)
- [Drupal configuration management](https://www.drupal.org/docs/administering-a-drupal-site/configuration-management/workflow-using-drush)
