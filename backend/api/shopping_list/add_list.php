<?php
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/auth_middleware.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') error('Method not allowed', 405);

$user  = authenticate();
$body  = bodyJson();
$title = trim($body['title'] ?? '');
$month = (int)($body['month'] ?? date('n'));
$year  = (int)($body['year']  ?? date('Y'));

if (!$title) error('List title is required');

$db   = getDB();
$stmt = $db->prepare('INSERT INTO shopping_lists (id_user, title, month, year) VALUES (?, ?, ?, ?)');
$stmt->bind_param('isii', $user['id_user'], $title, $month, $year);
$stmt->execute();
$id = $db->insert_id;
$db->close();

success(['id_shopping_list' => $id], 'Shopping list created');