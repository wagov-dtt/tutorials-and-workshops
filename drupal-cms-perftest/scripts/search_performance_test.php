<?php

/**
 * @file
 * Search API performance testing script.
 */

use Drupal\search_api\Entity\Index;

$search_terms = [
  'breaking news', 'technology', 'market analysis', 'health', 'politics',
  'environment', 'sports', 'economy', 'science', 'education',
  'weather', 'transportation', 'housing', 'energy', 'agriculture',
  'manufacturing', 'tourism', 'healthcare', 'legal', 'community'
];

$num_searches = 100;
$results_per_page = 20;

echo "Starting Search API performance test...\n";
echo "Running $num_searches searches with $results_per_page results per page\n\n";

// Get the content search index
$index = Index::load('content');
if (!$index) {
  echo "Error: Could not load 'content' search index. Make sure Search API is configured.\n";
  exit(1);
}

$total_time = 0;
$search_times = [];
$total_results = 0;

for ($i = 0; $i < $num_searches; $i++) {
  $search_term = $search_terms[array_rand($search_terms)];
  
  $start_time = microtime(true);
  
  // Create search query
  $query = $index->query();
  $query->keys($search_term);
  $query->setOption('limit', $results_per_page);
  $query->setOption('offset', 0);
  
  // Execute search
  $results = $query->execute();
  
  $end_time = microtime(true);
  $search_time = ($end_time - $start_time) * 1000; // Convert to milliseconds
  
  $search_times[] = $search_time;
  $total_time += $search_time;
  $result_count = $results->getResultCount();
  $total_results += $result_count;
  
  echo sprintf("Search %d: '%s' - %d results in %.2fms\n", 
    $i + 1, $search_term, $result_count, $search_time);
  
  // Small delay to prevent overwhelming the system
  usleep(10000); // 10ms delay
}

// Calculate statistics
$avg_time = $total_time / $num_searches;
$avg_results = $total_results / $num_searches;

sort($search_times);
$median_time = $search_times[intval($num_searches / 2)];
$min_time = min($search_times);
$max_time = max($search_times);

// Calculate 95th percentile
$percentile_95_index = intval($num_searches * 0.95);
$percentile_95_time = $search_times[$percentile_95_index];

echo "\n" . str_repeat("=", 50) . "\n";
echo "PERFORMANCE SUMMARY\n";
echo str_repeat("=", 50) . "\n";
echo sprintf("Total searches: %d\n", $num_searches);
echo sprintf("Average results per search: %.1f\n", $avg_results);
echo sprintf("Total search time: %.2fms\n", $total_time);
echo sprintf("Average search time: %.2fms\n", $avg_time);
echo sprintf("Median search time: %.2fms\n", $median_time);
echo sprintf("Min search time: %.2fms\n", $min_time);
echo sprintf("Max search time: %.2fms\n", $max_time);
echo sprintf("95th percentile: %.2fms\n", $percentile_95_time);
echo sprintf("Searches per second: %.1f\n", 1000 / $avg_time);

// Performance rating
if ($avg_time < 50) {
  $rating = "Excellent";
} elseif ($avg_time < 100) {
  $rating = "Good"; 
} elseif ($avg_time < 200) {
  $rating = "Fair";
} else {
  $rating = "Needs improvement";
}

echo sprintf("Performance rating: %s\n", $rating);

// Get index statistics
$server = $index->getServerInstance();
echo "\n" . str_repeat("-", 30) . "\n";
echo "INDEX INFORMATION\n";
echo str_repeat("-", 30) . "\n";
echo sprintf("Index name: %s\n", $index->label());
echo sprintf("Server: %s (%s)\n", $server->label(), $server->getBackendId());
echo sprintf("Total indexed items: %d\n", $index->getTrackerInstance()->getIndexedItemsCount());
echo sprintf("Items to be indexed: %d\n", $index->getTrackerInstance()->getTotalItemsCount() - $index->getTrackerInstance()->getIndexedItemsCount());
