<?php

include_once '../config/response.php';
include_once '../config/database.php';

/** @var mysqli $conn */

$id_category = $_GET['id_category'] ?? null;
$id_user = $_GET['id_user'] ?? null;

if (!$id_category || !$id_user) {
    echo json_encode([
        "success" => false,
        "message" => "id_category dan id_user wajib diisi"
    ]);
    exit;
}

$sql = "SELECT * FROM item 
        WHERE id_category = ? 
        AND id_user = ? 
        ORDER BY id_item DESC";

$stmt = $conn->prepare($sql);
$stmt->bind_param("ii", $id_category, $id_user);
$stmt->execute();

$result = $stmt->get_result();

$data = [];

while ($row = $result->fetch_assoc()) {
    $data[] = $row;
}

echo json_encode([
    "success" => true,
    "id_category" => $id_category,
    "id_user" => $id_user,
    "data" => $data
]);