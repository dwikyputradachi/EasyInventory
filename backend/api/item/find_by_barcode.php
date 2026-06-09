<?php

include_once '../config/response.php';
include_once '../config/database.php';

/** @var mysqli $conn */

$barcode = $_GET['barcode'] ?? '';

if ($barcode === '') {
    echo json_encode([
        "success" => false,
        "message" => "Barcode wajib diisi"
    ]);
    exit;
}

$sql = "SELECT * FROM item WHERE barcode = ? ORDER BY id_item DESC LIMIT 1";

$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $barcode);
$stmt->execute();

$result = $stmt->get_result();

if ($result->num_rows === 0) {
    http_response_code(404);
    echo json_encode([
        "success" => false,
        "message" => "Barcode belum ditemukan"
    ]);
    exit;
}

echo json_encode([
    "success" => true,
    "data" => $result->fetch_assoc()
]);