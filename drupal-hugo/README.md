# Drupal CMS with Hugo static-site experiments

Local Drupal CMS lab using [DDEV](https://ddev.com/) and Composer. The current focus is running Drupal locally and experimenting with Drupal-to-static-site workflows.

## Quick start

From the repo root:

```bash
just drupal::deploy
just drupal::smoke
just drupal::urls
```

Or from this directory:

```bash
cd drupal-hugo
ddev start
ddev launch
```

`ddev start` runs this repo's bootstrap hook automatically.

## Bootstrap Drupal files

To recreate Composer-managed Drupal CMS files manually:

```bash
ddev composer bootstrap
```

That shortcut runs `composer install` and `composer drupal:recipe-unpack`. It restores:

- `vendor/`
- Drupal core and contributed code under `web/`
- scaffolded web-root files
- unpacked recipes from `composer.lock`

Use `composer install` for normal setup. Update dependencies intentionally and commit `composer.json` and `composer.lock` together.

## Useful DDEV commands

```bash
ddev start
ddev launch
ddev drush status
ddev drush user:login
ddev drush cache:rebuild
ddev stop
```

## What to study

| Path | Purpose |
|------|---------|
| `.ddev/config.yaml` | DDEV project config |
| `composer.json` | PHP/Drupal dependencies and scripts |
| `composer.lock` | Reproducible dependency graph |
| `justfile` | Repo wrapper recipes |
| `AGENTS.md` | Local Drupal workflow notes for coding agents |

## Guardrails

- Do not commit secrets, `.env`, `settings.local.php`, or `.ddev/config.local.yaml`.
- Do not commit `vendor/` or uploaded files under `web/sites/*/files`.
- Do not edit Drupal core or contributed modules in place.
- Put custom code under `web/modules/custom` or `web/themes/custom`.

## References

- [DDEV Drupal quickstart](https://docs.ddev.com/en/stable/users/quickstart/#drupal-drupal-cms)
- [Drupal CMS user guide](https://project.pages.drupalcode.org/drupal_cms/)
- [Drupal User Guide](https://www.drupal.org/docs/user_guide/en/index.html)
- [Drush documentation](https://www.drush.org/)
- [Composer documentation](https://getcomposer.org/doc/)

## Support and upstream

Drupal CMS is developed at <https://www.drupal.org/project/drupal_cms>. For upstream bugs, use the [Drupal CMS issue queue](https://drupal.org/node/add/project-issue/drupal_cms) or the Drupal Slack community.

## License

Drupal CMS and derivative works are licensed under the [GNU General Public License, version 2 or later](http://www.gnu.org/licenses/old-licenses/gpl-2.0.html). See the [Drupal trademark and logo policy](https://www.drupal.com/trademark) for brand usage.
