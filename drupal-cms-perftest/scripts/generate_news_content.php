<?php

/**
 * @file
 * Generates news content for performance testing.
 */

use Drupal\node\Entity\Node;

// Configuration
$total_articles = 1000;
$batch_size = 100;

echo "Generating $total_articles news articles...\n";

$titles = ["Breaking News", "Market Update", "Tech News", "Sports Report", "Weather Alert"];
$content = "This is sample news content for performance testing. ";

for ($i = 1; $i <= $total_articles; $i++) {
  $node = Node::create([
    'type' => 'news',
    'title' => $titles[array_rand($titles)] . " #$i",
    'body' => ['value' => $content . "Article number $i.", 'format' => 'basic_html'],
    'status' => 1,
    'uid' => 1,
  ]);
  $node->save();

  if ($i % $batch_size === 0) {
    echo "Created $i articles\n";
    \Drupal::service('entity.memory_cache')->deleteAll();
  }
}

echo "Generated $total_articles news articles.\n";
