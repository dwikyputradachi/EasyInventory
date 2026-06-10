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
    $data[] = $row;
}

$db->close();

success($data, "Items loaded");