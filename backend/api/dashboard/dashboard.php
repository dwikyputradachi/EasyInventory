<?php

include_once '../config/response.php';
include_once '../config/database.php';

/** @var mysqli $conn */

$id_user = $_GET['id_user'] ?? null;

if (!$id_user) {
    echo json_encode([
        "success" => false,
        "message" => "id_user wajib diisi"
    ]);
    exit;
}

$today = date("Y-m-d");
$nearExpiryDate = date("Y-m-d", strtotime("+7 days"));

// Total items
$stmt = $conn->prepare("SELECT COUNT(*) AS total FROM item WHERE id_user = ?");
$stmt->bind_param("i", $id_user);
$stmt->execute();
$totalItems = $stmt->get_result()->fetch_assoc()['total'];

// Low stock
$stmt = $conn->prepare("SELECT COUNT(*) AS total FROM item WHERE id_user = ? AND stok <= 5");
$stmt->bind_param("i", $id_user);
$stmt->execute();
$lowStock = $stmt->get_result()->fetch_assoc()['total'];

// Near expired
$stmt = $conn->prepare("
    SELECT COUNT(*) AS total
    FROM item
    WHERE id_user = ?
    AND expired_date IS NOT NULL
    AND expired_date > ?
    AND expired_date <= ?
");
$stmt->bind_param("iss", $id_user, $today, $nearExpiryDate);
$stmt->execute();
$nearExpired = $stmt->get_result()->fetch_assoc()['total'];

// Expired
$stmt = $conn->prepare("
    SELECT COUNT(*) AS total
    FROM item
    WHERE id_user = ?
    AND expired_date IS NOT NULL
    AND expired_date <= ?
");
$stmt->bind_param("is", $id_user, $today);
$stmt->execute();
$expired = $stmt->get_result()->fetch_assoc()['total'];

// Notifications terbaru yang unread milik user ini
$stmt = $conn->prepare("
    SELECT 
        notification.id_notification,
        notification.id_item,
        notification.type,
        notification.title,
        notification.message,
        notification.created_at
    FROM notification
    INNER JOIN item ON notification.id_item = item.id_item
    WHERE item.id_user = ?
    AND notification.is_read = 0
    ORDER BY notification.created_at DESC
    LIMIT 5
");
$stmt->bind_param("i", $id_user);
$stmt->execute();

$result = $stmt->get_result();
$notifications = [];

while ($row = $result->fetch_assoc()) {
    $notifications[] = $row;
}

echo json_encode([
    "success" => true,
    "data" => [
        "total_items" => (int)$totalItems,
        "low_stock" => (int)$lowStock,
        "near_expired" => (int)$nearExpired,
        "expired" => (int)$expired,
        "notifications" => $notifications
    ]
]);