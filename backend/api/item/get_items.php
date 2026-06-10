<?php
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/auth_middleware.php';

$user = authenticate();

$db   = getDB();
$stmt = $db->prepare('
    SELECT i.id_item, i.name, i.quantity, i.stok, i.price, i.unit, i.barcode, i.expired_date,
           c.name_category
    FROM item i
    JOIN category c ON i.id_category = c.id_category
    WHERE i.id_user = ?
    ORDER BY i.expired_date ASC
');
$stmt->bind_param('i', $user['id_user']);
$stmt->execute();
$data = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
$db->close();

success($data);
