<?php

/**
 * @file
 * Generates news content for performance testing.
 */

use Drupal\node\Entity\Node;

// Configuration
$total_articles = 100000;
$batch_size = 500;  // Increased for better performance with 2GB memory

// Check existing content count
try {
  $query = \Drupal::entityQuery('node')
    ->condition('type', 'news')
    ->accessCheck(FALSE);
  $existing_count = $query->count()->execute();
} catch (Exception $e) {
  // If query fails (content type doesn't exist yet), assume 0
  $existing_count = 0;
  echo "⚠️  News content type not ready yet, starting from 0\n";
}

echo "Target: $total_articles articles\n";
echo "Existing: $existing_count articles\n";

if ($existing_count >= $total_articles) {
  echo "✅ Already have $existing_count articles (target: $total_articles). Nothing to generate.\n";
  return;
}

$articles_to_create = $total_articles - $existing_count;
echo "📝 Generating $articles_to_create additional articles...\n";

$titles = [
  "Breaking News", "Market Update", "Tech News", "Sports Report", "Weather Alert",
  "Economic Analysis", "Political Development", "Health Research", "Environmental Study",
  "Innovation Report", "Cultural Event", "Education Reform", "Transportation Update"
];

// Generate 1-2 pages of realistic content
$paragraphs = [
  "In a rapidly evolving digital landscape, organizations across various sectors are experiencing unprecedented challenges and opportunities. The integration of advanced technologies has fundamentally transformed how businesses operate, communicate, and deliver value to their stakeholders.",
  "Recent studies indicate that companies implementing comprehensive digital transformation strategies report significant improvements in operational efficiency and customer satisfaction. These findings highlight the critical importance of strategic planning and resource allocation in today's competitive environment.",
  "Industry experts emphasize that successful adaptation requires not only technological investment but also cultural shifts within organizations. Leadership teams must foster innovation while maintaining operational stability and regulatory compliance.",
  "The implications of these developments extend beyond individual companies to entire economic ecosystems. Supply chain relationships, market dynamics, and consumer expectations continue to evolve at an accelerating pace.",
  "Data analytics and artificial intelligence have emerged as key differentiators in this transformation. Organizations leveraging these capabilities demonstrate enhanced decision-making processes and more effective resource utilization.",
  "Furthermore, sustainability considerations have become integral to strategic planning. Companies are increasingly required to balance profitability with environmental responsibility and social impact.",
  "The global nature of modern commerce presents both opportunities for expansion and challenges related to regulatory compliance across different jurisdictions. International partnerships and collaboration have become essential for sustained growth.",
  "As we look toward the future, the ability to adapt quickly to changing circumstances while maintaining core business values will determine long-term success. Investment in human capital and continuous learning remains paramount."
];

// Generate content for remaining articles
for ($i = 1; $i <= $articles_to_create; $i++) {
  $content = implode("\n\n", array_slice($paragraphs, 0, rand(4, 6)));
  $article_number = $existing_count + $i;
  
  $node = Node::create([
    'type' => 'news',
    'title' => $titles[array_rand($titles)] . " #$article_number",
    'body' => ['value' => $content . " Article number $article_number.", 'format' => 'basic_html'],
    'status' => 1,
    'uid' => 1,
  ]);
  $node->save();

  if ($i % $batch_size === 0) {
    $current_total = $existing_count + $i;
    echo "Created $i new articles ($current_total total)\n";
    \Drupal::service('entity.memory_cache')->deleteAll();
  }
}

$final_count = $existing_count + $articles_to_create;
echo "✅ Complete! Generated $articles_to_create new articles. Total: $final_count articles.\n";
