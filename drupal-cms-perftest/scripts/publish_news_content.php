<?php

/**
 * @file
 * Publishes all unpublished news content.
 */

// Publish all draft news articles
$database = \Drupal::database();
$result = $database->update('node_field_data')
  ->fields(['status' => 1])
  ->condition('type', 'news')
  ->condition('status', 0)
  ->execute();

echo "Published $result news articles.\n";
