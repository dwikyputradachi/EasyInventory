<?php

include_once '../config/response.php';
include_once '../config/database.php';

/** @var mysqli $conn */

$id_item = $_GET['id_item'] ?? null;

if (!$id_item) {
    echo json_encode([
        "success" => false,
        "message" => "id_item wajib diisi"
    ]);
    exit;
}

$checkItem = $conn->prepare("SELECT * FROM item WHERE id_item = ?");
$checkItem->bind_param("i", $id_item);
$checkItem->execute();

if ($checkItem->get_result()->num_rows === 0) {
    http_response_code(404);
    echo json_encode([
        "success" => false,
        "message" => "Item tidak ditemukan"
    ]);
    exit;
}

// Hapus notifikasi yang berkaitan dengan item ini
$deleteNotif = $conn->prepare("DELETE FROM notification WHERE id_item = ?");
$deleteNotif->bind_param("i", $id_item);
$deleteNotif->execute();

// Hapus item
$deleteItem = $conn->prepare("DELETE FROM item WHERE id_item = ?");
$deleteItem->bind_param("i", $id_item);

if ($deleteItem->execute()) {
    echo json_encode([
        "success" => true,
        "message" => "Produk berhasil dihapus"
    ]);
} else {
    echo json_encode([
        "success" => false,
        "message" => "Produk gagal dihapus"
    ]);
}