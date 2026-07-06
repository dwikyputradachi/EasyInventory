<?php
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/auth_middleware.php';

$user  = authenticate();
$year  = (int)($_GET['year'] ?? date('Y'));
$month = (int)($_GET['month'] ?? date('m'));

$db = getDB();

$stmt = $db->prepare('
    SELECT 
        r.id_receipt,
        r.name AS receipt_name,
        r.created_at,
        ri.name AS item_name,
        ri.quantity,
        ri.price,
        c.name_category
    FROM receipt r
    JOIN receipt_item ri ON r.id_receipt = ri.id_receipt
    LEFT JOIN category c ON ri.id_category = c.id_category
    WHERE r.id_user = ?
      AND YEAR(r.created_at) = ?
      AND MONTH(r.created_at) = ?
    ORDER BY r.created_at DESC, ri.id_receipt_item ASC
');

$stmt->bind_param('iii', $user['id_user'], $year, $month);
$stmt->execute();

$result = $stmt->get_result();

$receipts = [];

while ($row = $result->fetch_assoc()) {
    $id = $row['id_receipt'];

    if (!isset($receipts[$id])) {
        $receipts[$id] = [
            'id_receipt' => $id,
            'title' => $row['receipt_name'],
            'date' => $row['created_at'],
            'total' => 0,
            'items' => []
        ];
    }

    $qty = (int)$row['quantity'];
    $price = (float)$row['price'];
    $subtotal = $qty * $price;

    $receipts[$id]['total'] += $subtotal;

    $receipts[$id]['items'][] = [
        'name' => $row['item_name'],
        'quantity' => $qty,
        'price' => $price,
        'category' => $row['name_category'] ?? 'Others'
    ];
}

$db->close();

success(array_values($receipts), 'Receipt history loaded');