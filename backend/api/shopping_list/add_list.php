<?php
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/auth_middleware.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') error('Method not allowed', 405);

$user = authenticate();

$body = bodyJson();
$title = trim($body['title'] ?? '');

if (!$title) error('List title is required');

$db = getDB();

$stmt = $db->prepare('INSERT INTO shopping_lists (id_user, title) VALUES (?, ?)');
$stmt->bind_param('is', $user['id_user'], $title);
$stmt->execute();

$id = $db->insert_id;

$stmt->close();
$db->close();

success(['id_shopping_list' => $id], 'Shopping list created');