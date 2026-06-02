<?php
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/auth_middleware.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') error('Method not allowed', 405);

authenticate();

$body = bodyJson();

$id_shopping_list = (int)($body['id_shopping_list'] ?? 0);
$name_item = trim($body['name_item'] ?? '');
$qty = (int)($body['quantity'] ?? 1);
$unit = trim($body['unit'] ?? 'pcs');
$priority = trim($body['priority'] ?? 'Medium');

if (!$id_shopping_list || !$name_item) {
    error('id_shopping_list and name_item are required');
}

$db = getDB();

$stmt = $db->prepare(
    'INSERT INTO shopping_list_items 
    (id_shopping_list, name_item, quantity, unit, priority) 
    VALUES (?, ?, ?, ?, ?)'
);

$stmt->bind_param('isiss', $id_shopping_list, $name_item, $qty, $unit, $priority);
$stmt->execute();

$id = $db->insert_id;

$stmt->close();
$db->close();

success(['id_shopping_item' => $id], 'Item added to list');