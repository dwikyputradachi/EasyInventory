<?php
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/auth_middleware.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') error('Method not allowed', 405);

$user = authenticate();
$body = bodyJson();

$name        = trim($body['name']         ?? '');
$id_category = (int)($body['id_category'] ?? 0);
$quantity    = (int)($body['quantity']    ?? 0);
$stok        = (int)($body['stok']        ?? 0);
$price       = (float)($body['price']     ?? 0);
$unit        = trim($body['unit']         ?? 'pcs');
$barcode     = trim($body['barcode']      ?? '');
$expired     = trim($body['expired_date'] ?? '');

if (!$name || !$id_category || !$expired) error('Name, category, and expired date are required');

$db   = getDB();
$stmt = $db->prepare('
    INSERT INTO item (id_user, id_category, name, quantity, stok, price, unit, barcode, expired_date)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
');
$stmt->bind_param('iisiidss s', $user['id_user'], $id_category, $name, $quantity, $stok, $price, $unit, $barcode, $expired);
$stmt->execute();
$id = $db->insert_id;
$db->close();

success(['id_item' => $id], 'Item added');
