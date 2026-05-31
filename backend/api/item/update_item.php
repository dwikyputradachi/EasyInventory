<?php
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/auth_middleware.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') error('Method not allowed', 405);

$user = authenticate();
$body = bodyJson();

$id_item  = (int)($body['id_item']      ?? 0);
$name     = trim($body['name']          ?? '');
$quantity = (int)($body['quantity']     ?? 0);
$stok     = (int)($body['stok']         ?? 0);
$price    = (float)($body['price']      ?? 0);
$unit     = trim($body['unit']          ?? 'pcs');
$expired  = trim($body['expired_date']  ?? '');

if (!$id_item || !$name || !$expired) error('id_item, name, and expired_date are required');

$db   = getDB();
$stmt = $db->prepare('
    UPDATE item SET name=?, quantity=?, stok=?, price=?, unit=?, expired_date=?
    WHERE id_item=? AND id_user=?
');
$stmt->bind_param('siidssii', $name, $quantity, $stok, $price, $unit, $expired, $id_item, $user['id_user']);
$stmt->execute();
$db->close();

success(null, 'Item updated');
