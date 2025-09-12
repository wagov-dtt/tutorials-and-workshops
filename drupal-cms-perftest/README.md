# Drupal CMS Performance Testing

Performance testing environment for Drupal CMS with focus on content generation and search functionality.

## Quick Start

1. **Setup**: `just setup` - Install Drupal CMS with search and news recipes
2. **Restart**: `ddev restart` - Apply performance configurations  
3. **Generate**: `just generate` - Create 100,000 test news articles (resumes if partial)  
4. **Test**: `just test` - Run search performance benchmarks
5. **Clear**: `just clear` - Remove test content

**Note**: Performance configurations are included and committed to the repository.

## Available Commands

Run `just` to see all available commands:

```bash
# Setup and basic operations
just setup      # Install Drupal CMS with search/news
just start      # Start DDEV containers
just stop       # Stop DDEV containers  
just login      # Get admin login link
just status     # Show DDEV project status
just reset      # Delete and recreate DDEV project

# Content generation and testing
just generate   # Create test content and index for search
just test       # Run search performance tests
just clear      # Delete test content
just full-test  # Complete workflow: generate + test
```

## Configuration

Edit `scripts/generate_news_content.php` to change:
- `$total_articles` - Target number of total articles (default: 100,000)
- `$batch_size` - Processing batch size (default: 100)

**Smart Resume**: Script automatically counts existing articles and only generates the remainder to reach the target. Run multiple times safely - it won't create duplicates.

Each article contains 1-2 pages of realistic content for comprehensive performance testing.

## Performance Optimizations

**Pre-configured for 100K+ articles** - Run `ddev restart` after setup to apply optimizations.

### PHP Configuration
- **Memory limit**: 2GB for large content operations  
- **OPcache**: 512MB cache with 20,000 max files
- **Execution time**: 10 minutes for bulk generation
- **File**: [`.ddev/php/performance.ini`](file:///home/adonm/tutorials-and-workshops/drupal-cms-perftest/.ddev/php/performance.ini) *(committed to repo)*

### MariaDB Configuration  
- **Buffer pool**: 1GB InnoDB buffer for caching
- **Query cache**: 128MB for repeated searches
- **Connections**: 200 max concurrent connections
- **Timeouts**: Extended for bulk operations
- **File**: [`.ddev/mysql/performance.cnf`](file:///home/adonm/tutorials-and-workshops/drupal-cms-perftest/.ddev/mysql/performance.cnf) *(committed to repo)*

## Research & Findings

### Search API Issues Encountered

1. **Index Tracking Problem**: Search API tracker wasn't recognizing newly created content
   - **Solution**: Use `search-api:rebuild-tracker` after content generation
   - **Root cause**: Tracker established before content types were fully configured

2. **Bundle Configuration**: Default bundle tracking (`default: true`) didn't work initially
   - **Issue**: Configuration was set correctly but tracker cache wasn't updated
   - **Fix**: Clear search index and rebuild tracker completely

3. **Memory Issues**: Large content generation caused PHP memory exhaustion
   - **Solution**: Process in batches and clear entity cache between batches
   - **Best practice**: Use `entity.memory_cache::deleteAll()` for large operations

### Performance Characteristics

Based on testing with 100,000 articles:
- **Generation**: ~10-20 articles/second depending on field complexity  
- **Indexing**: Search API can index ~50-100 items/second
- **Search**: Performance varies with content size and search complexity

## Useful Resources

### Drupal CMS Documentation
- [Drupal CMS Project](https://www.drupal.org/project/drupal_cms)
- [Recipe System](https://www.drupal.org/docs/drupal-apis/recipe-system)
- [Installation Guide](https://new.drupal.org/docs/drupal-cms)

### Search API Resources  
- [Search API Module](https://www.drupal.org/project/search_api)
- [Search API Documentation](https://www.drupal.org/docs/contributed-modules/search-api)
- [Performance Optimization](https://www.drupal.org/docs/contributed-modules/search-api/getting-started/frequently-asked-questions#performance)

### Performance Testing
- [Drupal Performance Guide](https://www.drupal.org/docs/administering-a-drupal-site/optimizing-performance)
- [Database Performance](https://www.drupal.org/docs/system-requirements/database-requirements)

### DDEV Resources
- [DDEV Documentation](https://ddev.readthedocs.io/)
- [DDEV Commands](https://ddev.readthedocs.io/en/stable/users/cli-usage/)

## Troubleshooting

### Search Not Working
```bash
# Check index status
ddev drush search-api:status

# Rebuild and reindex
just generate
```

### Content Generation Fails
```bash  
# Check for memory/timeout issues
ddev drush php:eval "echo ini_get('memory_limit');"

# Clear existing content first
just clear
```

### DDEV Issues
```bash
# Restart DDEV
just stop && just start

# Complete reset
just reset && just setup
```

## Development Notes

- Uses simplified PHP scripts instead of complex custom code
- Leverages core Drupal/Drush commands where possible  
- Batch processing prevents memory issues with large datasets
- Search API database backend for consistent performance testing
- Minimal dependencies - only essential modules installed
