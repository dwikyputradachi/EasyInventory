<?php

include_once '../config/response.php';
include_once '../config/database.php';
include_once '../config/notification_helper.php';

/** @var mysqli $conn */

$id_item = $_GET['id_item'] ?? null;
$data = json_decode(file_get_contents("php://input"), true);

if (!$id_item) {
    echo json_encode([
        "success" => false,
        "message" => "id_item wajib diisi"
    ]);
    exit;
}

$quantity = $data['quantity'] ?? null;

if ($quantity === null) {
    echo json_encode([
        "success" => false,
        "message" => "quantity wajib diisi"
    ]);
    exit;
}

$checkItem = $conn->prepare("SELECT * FROM item WHERE id_item = ?");
$checkItem->bind_param("i", $id_item);
$checkItem->execute();
$result = $checkItem->get_result();

if ($result->num_rows === 0) {
    http_response_code(404);
    echo json_encode([
        "success" => false,
        "message" => "Item tidak ditemukan"
    ]);
    exit;
}

$sql = "UPDATE item SET quantity = ?, stok = ? WHERE id_item = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("iii", $quantity, $quantity, $id_item);

if (!$stmt->execute()) {
    echo json_encode([
        "success" => false,
        "message" => "Stock gagal diupdate"
    ]);
    exit;
}

$get = $conn->prepare("SELECT * FROM item WHERE id_item = ?");
$get->bind_param("i", $id_item);
$get->execute();
$updatedItem = $get->get_result()->fetch_assoc();

syncItemNotifications($conn, $updatedItem);

echo json_encode([
    "success" => true,
    "message" => "Stock berhasil diupdate",
    "data" => $updatedItem
]);