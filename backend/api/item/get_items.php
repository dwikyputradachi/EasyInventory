<?php
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/auth_middleware.php';

$user = authenticate();
$id_user = (int)$user['id_user'];

$id_category = $_GET['id_category'] ?? null;

if (!$id_category) {
    error('id_category wajib diisi', 400);
}

$db = getDB();

function getExpiredStatus($expired_date) {
    if ($expired_date == null || $expired_date == '') {
        return 'no_expiry';
    }

    $today = new DateTime(date("Y-m-d"));
    $expiredDate = new DateTime($expired_date);

    $daysLeft = (int)$today->diff($expiredDate)->format("%r%a");

    if ($daysLeft <= 0) {
        return 'expired';
    }

    if ($daysLeft <= 7) {
        return 'near_expired';
    }

    return 'safe';
}

$sql = "SELECT 
            id_item,
            id_category,
            id_user,
            name,
            quantity,
            stok,
            price,
            unit,
            barcode,
            expired_date
        FROM item 
        WHERE id_category = ? 
        AND id_user = ? 
        ORDER BY id_item DESC";

$stmt = $db->prepare($sql);
$stmt->bind_param("ii", $id_category, $id_user);
$stmt->execute();

$result = $stmt->get_result();
$data = [];

while ($row = $result->fetch_assoc()) {
    $row['expired_status'] = getExpiredStatus($row['expired_date']);
    $data[] = $row;
}

$db->close();

success($data, "Items loaded");