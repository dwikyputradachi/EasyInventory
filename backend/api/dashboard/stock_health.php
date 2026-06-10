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
    SUM(CASE WHEN stok <= 0 THEN 1 ELSE 0 END) AS out_of_stock,
    SUM(CASE WHEN stok > 0 AND stok <= 5 THEN 1 ELSE 0 END) AS low_stock,
    SUM(CASE WHEN stok > 5 THEN 1 ELSE 0 END) AS healthy
FROM item
WHERE id_user = ?";

$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $id_user);
$stmt->execute();

$data = $stmt->get_result()->fetch_assoc();

echo json_encode([
    "success" => true,
    "data" => [
        "out_of_stock" => (int)$data["out_of_stock"],
        "low_stock" => (int)$data["low_stock"],
        "healthy" => (int)$data["healthy"],
    ]
]);