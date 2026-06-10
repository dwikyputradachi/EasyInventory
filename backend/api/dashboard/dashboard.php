<?php
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/auth_middleware.php';

$user = authenticate();
$id_user = (int)$user['id_user'];

$db = getDB();

$today = date("Y-m-d");
$nearExpiryDate = date("Y-m-d", strtotime("+7 days"));

// Total items
$stmt = $db->prepare("SELECT COUNT(*) AS total FROM item WHERE id_user = ?");
$stmt->bind_param("i", $id_user);
$stmt->execute();
$totalItems = $stmt->get_result()->fetch_assoc()['total'] ?? 0;

// Low stock
$stmt = $db->prepare("SELECT COUNT(*) AS total FROM item WHERE id_user = ? AND stok <= 5");
$stmt->bind_param("i", $id_user);
$stmt->execute();
$lowStock = $stmt->get_result()->fetch_assoc()['total'] ?? 0;

// Near expired
$stmt = $db->prepare("
    SELECT COUNT(*) AS total
    FROM item
    WHERE id_user = ?
    AND expired_date IS NOT NULL
    AND expired_date > ?
    AND expired_date <= ?
");
$stmt->bind_param("iss", $id_user, $today, $nearExpiryDate);
$stmt->execute();
$nearExpired = $stmt->get_result()->fetch_assoc()['total'] ?? 0;

// Expired
$stmt = $db->prepare("
    SELECT COUNT(*) AS total
    FROM item
    WHERE id_user = ?
    AND expired_date IS NOT NULL
    AND expired_date <= ?
");
$stmt->bind_param("is", $id_user, $today);
$stmt->execute();
$expired = $stmt->get_result()->fetch_assoc()['total'] ?? 0;

// Notifications terbaru
$stmt = $db->prepare("
    SELECT 
        n.id_notification,
        n.id_item,
        n.type,
        n.title,
        n.message,
        n.created_at
    FROM notification n
    INNER JOIN item i ON n.id_item = i.id_item
    WHERE i.id_user = ?
    AND n.is_read = 0
    ORDER BY n.created_at DESC
    LIMIT 5
");
$stmt->bind_param("i", $id_user);
$stmt->execute();

$result = $stmt->get_result();
$notifications = [];

while ($row = $result->fetch_assoc()) {
    $notifications[] = $row;
}

// Shopping progress
$purchased = 0;
$totalShopping = 0;

$stmt = $db->prepare("
    SELECT 
        COUNT(sli.id_shopping_item) AS total,
        COALESCE(SUM(CASE WHEN sli.is_bought = 1 THEN 1 ELSE 0 END), 0) AS purchased
    FROM shopping_lists sl
    INNER JOIN shopping_list_items sli 
        ON sl.id_shopping_list = sli.id_shopping_list
    WHERE sl.id_user = ?
      AND sl.status = 'active'
");
$stmt->bind_param("i", $id_user);
$stmt->execute();

$shopping = $stmt->get_result()->fetch_assoc();

if ($shopping) {
    $totalShopping = (int)($shopping['total'] ?? 0);
    $purchased = (int)($shopping['purchased'] ?? 0);
}

$db->close();

success([
    "total_items" => (int)$totalItems,
    "low_stock" => (int)$lowStock,
    "near_expired" => (int)$nearExpired,
    "expired" => (int)$expired,
    "notifications" => $notifications,
    "shopping_progress" => [
        "purchased" => $purchased,
        "total" => $totalShopping
    ]
]);