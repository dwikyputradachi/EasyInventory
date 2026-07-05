<?php


include_once '../config/response.php';
include_once '../config/database.php';

$conn = getDB();

$data = json_decode(file_get_contents("php://input"), true);

$id_item = $data['id_item'] ?? null;

if (!$id_item) {
    echo json_encode([
        "success" => false,
        "message" => "id_item wajib diisi"
    ]);
    exit;
}

$name = $data['name'] ?? null;
$quantity = $data['quantity'] ?? null;
$stok = $quantity;
$price = $data['price'] ?? 0;
$unit = $data['unit'] ?? null;
$barcode = $data['barcode'] ?? null;
$expired_date = $data['expired_date'] ?? null;

if (!$name || $quantity === null) {
    echo json_encode([
        "success" => false,
        "message" => "Data wajib belum lengkap"
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

$sql = "UPDATE item 
        SET name = ?, quantity = ?, stok = ?, price = ?, unit = ?, barcode = ?, expired_date = ?
        WHERE id_item = ?";

$stmt = $conn->prepare($sql);
$stmt->bind_param(
    "siidsssi",
    $name,
    $quantity,
    $stok,
    $price,
    $unit,
    $barcode,
    $expired_date,
    $id_item
);

if (!$stmt->execute()) {
    echo json_encode([
        "success" => false,
        "message" => "Produk gagal diupdate"
    ]);
    exit;
}

// Buat notifikasi low stock jika stok <= 5
if ($stok <= 5) {
    $type = "low_stock";
    $title = $name;
    $message = "Current stock: " . $stok;

    $check = $conn->prepare("SELECT id_notification FROM notification WHERE id_item = ? AND type = ? AND is_read = 0 LIMIT 1");
    $check->bind_param("is", $id_item, $type);
    $check->execute();

    if ($check->get_result()->num_rows === 0) {
        $insertNotif = $conn->prepare("INSERT INTO notification (id_item, title, message, type, is_read) VALUES (?, ?, ?, ?, 0)");
        $insertNotif->bind_param("isss", $id_item, $title, $message, $type);
        $insertNotif->execute();
    }
}

// Buat notifikasi expired / near expired
if (!empty($expired_date)) {
    $today = new DateTime(date("Y-m-d"));
    $expiredDate = new DateTime($expired_date);
    $daysLeft = (int)$today->diff($expiredDate)->format("%r%a");

    if ($daysLeft <= 0) {
        $type = "expired";
        $title = $name;
        $message = "Expired on " . $expiredDate->format("d M Y");
    } elseif ($daysLeft <= 7) {
        $type = "near_expired";
        $title = $name;
        $message = "Expires in " . $daysLeft . " day(s) (" . $expiredDate->format("d M Y") . ")";
    } else {
        $type = null;
    }

    if ($type !== null) {
        $check = $conn->prepare("SELECT id_notification FROM notification WHERE id_item = ? AND type = ? AND is_read = 0 LIMIT 1");
        $check->bind_param("is", $id_item, $type);
        $check->execute();

        if ($check->get_result()->num_rows === 0) {
            $insertNotif = $conn->prepare("INSERT INTO notification (id_item, title, message, type, is_read) VALUES (?, ?, ?, ?, 0)");
            $insertNotif->bind_param("isss", $id_item, $title, $message, $type);
            $insertNotif->execute();
        }
    }
}

$get = $conn->prepare("SELECT * FROM item WHERE id_item = ?");
$get->bind_param("i", $id_item);
$get->execute();
$item = $get->get_result()->fetch_assoc();

echo json_encode([
    "success" => true,
    "message" => "Produk berhasil diupdate",
    "data" => $item
]);