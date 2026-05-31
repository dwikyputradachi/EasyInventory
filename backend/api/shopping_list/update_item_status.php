<?php
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/auth_middleware.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') error('Method not allowed', 405);

authenticate();
$body        = bodyJson();
$id_list_item = (int)($body['id_list_item'] ?? 0);
$is_bought   = (int)($body['is_bought']    ?? 0);

if (!$id_list_item) error('id_list_item is required');

$db   = getDB();
$stmt = $db->prepare('UPDATE shopping_list_items SET is_bought = ? WHERE id_list_item = ?');
$stmt->bind_param('ii', $is_bought, $id_list_item);
$stmt->execute();
$db->close();

success(null, 'Status updated');
