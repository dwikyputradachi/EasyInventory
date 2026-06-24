<?php
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/auth_middleware.php';
require_once __DIR__ . '/../config/notification_helper.php';
require_once __DIR__ . '/../config/receipt_helper.php';

header('Content-Type: application/json');

$user = authenticate();
$id_user = (int)$user['id_user'];

$conn = getDB();

$data = json_decode(file_get_contents("php://input"), true);

$id_item = $_GET['id_item'] ?? ($data['id_item'] ?? null);
$id_item = $id_item !== null ? (int)$id_item : null;

$name = trim($data['name'] ?? '');
$quantity = $data['quantity'] ?? null;
$stok = $quantity;
$price = $data['price'] ?? 0;
$unit = $data['unit'] ?? null;
$barcode = $data['barcode'] ?? null;
$expired_date = $data['expired_date'] ?? null;

if ($expired_date === '') {
    $expired_date = null;
}

if (!$id_item) {
    echo json_encode([
        "success" => false,
        "message" => "id_item wajib diisi",
        "debug" => [
            "data" => $data
        ]
    ]);
    exit;
}

if (!$name || $quantity === null || !$unit) {
    echo json_encode([
        "success" => false,
        "message" => "Data wajib belum lengkap",
        "debug" => [
            "name" => $name,
            "quantity" => $quantity,
            "unit" => $unit,
            "data" => $data
        ]
    ]);
    exit;
}

$quantity = (int)$quantity;
$stok = (int)$stok;
$price = (float)$price;

if ($quantity < 0) {
    echo json_encode([
        "success" => false,
        "message" => "Quantity tidak boleh kurang dari 0"
    ]);
    exit;
}

$checkItem = $conn->prepare("
    SELECT * FROM item 
    WHERE id_item = ? AND id_user = ?
    LIMIT 1
");

if (!$checkItem) {
    echo json_encode([
        "success" => false,
        "message" => "Prepare check item failed",
        "error" => $conn->error
    ]);
    exit;
}

$checkItem->bind_param("ii", $id_item, $id_user);
$checkItem->execute();

$item = $checkItem->get_result()->fetch_assoc();

if (!$item) {
    http_response_code(404);
    echo json_encode([
        "success" => false,
        "message" => "Item tidak ditemukan",
        "debug" => [
            "id_item" => $id_item,
            "id_user" => $id_user
        ]
    ]);
    exit;
}

$oldStock = (int)$item['stok'];
$newStock = $quantity;
$restockQty = 0;

if ($newStock > $oldStock) {
    $restockQty = $newStock - $oldStock;

    if ($price <= 0) {
        echo json_encode([
            "success" => false,
            "message" => "Price wajib diisi saat quantity dinaikkan"
        ]);
        exit;
    }
}

$stmt = $conn->prepare("
    UPDATE item 
    SET 
        name = ?, 
        quantity = ?, 
        stok = ?, 
        price = ?, 
        unit = ?, 
        barcode = ?, 
        expired_date = ?
    WHERE id_item = ? AND id_user = ?
");

if (!$stmt) {
    echo json_encode([
        "success" => false,
        "message" => "Prepare update failed",
        "error" => $conn->error
    ]);
    exit;
}

$stmt->bind_param(
    "siidsssii",
    $name,
    $quantity,
    $stok,
    $price,
    $unit,
    $barcode,
    $expired_date,
    $id_item,
    $id_user
);

if (!$stmt->execute()) {
    echo json_encode([
        "success" => false,
        "message" => "Produk gagal diupdate",
        "error" => $stmt->error
    ]);
    exit;
}

// Kalau quantity dinaikkan dari Edit Product, simpan sebagai restock ke receipt
$receiptResult = null;

if ($restockQty > 0) {
    $receiptResult = createReceiptItem(
        $conn,
        $id_user,
        $id_item,
        $item['id_category'],
        $name,
        $restockQty,
        $price,
        'Restock from Edit Product'
    );

    if (!$receiptResult['success']) {
        echo json_encode([
            "success" => false,
            "message" => "Produk berhasil diupdate, tapi gagal masuk pengeluaran",
            "receipt_error" => $receiptResult
        ]);
        exit;
    }
}

$get = $conn->prepare("
    SELECT * FROM item 
    WHERE id_item = ? AND id_user = ?
    LIMIT 1
");

if (!$get) {
    echo json_encode([
        "success" => false,
        "message" => "Prepare get updated item failed",
        "error" => $conn->error
    ]);
    exit;
}

$get->bind_param("ii", $id_item, $id_user);
$get->execute();

$updatedItem = $get->get_result()->fetch_assoc();

syncItemNotifications($conn, $updatedItem);

echo json_encode([
    "success" => true,
    "message" => "Produk berhasil diupdate",
    "data" => $updatedItem,
    "restock_qty" => $restockQty,
    "receipt" => $receiptResult
]);
exit;