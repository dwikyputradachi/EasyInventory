<?php
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/auth_middleware.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') error('Method not allowed', 405);

authenticate();

$body = bodyJson();

$id_shopping_item = (int)($body['id_shopping_item'] ?? 0);
$is_bought = (int)($body['is_bought'] ?? 0);

if (!$id_shopping_item) error('id_shopping_item is required');

$db = getDB();

$stmt = $db->prepare(
    'UPDATE shopping_list_items SET is_bought = ? WHERE id_shopping_item = ?'
);

$stmt->bind_param('ii', $is_bought, $id_shopping_item);
$stmt->execute();

$stmt->close();
$db->close();

success(null, 'Status updated');