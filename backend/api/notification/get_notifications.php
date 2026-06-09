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

$sql = "SELECT 
            notification.*
        FROM notification
        INNER JOIN item 
            ON notification.id_item = item.id_item
        WHERE notification.is_read = 0
        AND item.id_user = ?
        ORDER BY notification.created_at DESC";

$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $id_user);
$stmt->execute();

$result = $stmt->get_result();
$data = [];

while ($row = $result->fetch_assoc()) {
    $data[] = $row;
}

echo json_encode([
    "success" => true,
    "message" => "Notifications loaded",
    "data" => $data
]);