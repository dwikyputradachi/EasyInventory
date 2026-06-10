<?php
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/auth_middleware.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') error('Method not allowed', 405);

$user    = authenticate();
$body    = bodyJson();
$id_item = (int)($body['id_item'] ?? 0);

if (!$id_item) error('id_item is required');

$db   = getDB();
$stmt = $db->prepare('DELETE FROM item WHERE id_item = ? AND id_user = ?');
$stmt->bind_param('ii', $id_item, $user['id_user']);
$stmt->execute();
$db->close();

success(null, 'Item deleted');
