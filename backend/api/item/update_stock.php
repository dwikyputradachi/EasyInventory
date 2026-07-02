<?php
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/auth_middleware.php';
require_once __DIR__ . '/../config/notification_helper.php';
require_once __DIR__ . '/../config/receipt_helper.php';
require_once __DIR__ . '/../config/shopping_match_helper.php';

header('Content-Type: application/json');

$user = authenticate();
$id_user = (int)$user['id_user'];

$conn = getDB();

$data = json_decode(file_get_contents("php://input"), true);

$id_item = isset($data['id_item']) ? (int)$data['id_item'] : null;
$change  = isset($data['change']) ? (int)$data['change'] : null;
$unit_price = isset($data['unit_price']) ? (float)$data['unit_price'] : 0;

// =====================================================
// VALIDATION
// =====================================================

if (!$id_item || $change === null) {
    echo json_encode([
        "success" => false,
        "message" => "id_item dan change wajib diisi",
        "debug" => [
            "id_item" => $id_item,
            "change" => $change,
            "data" => $data
        ]
    ]);
    exit;
}

if ($change == 0) {
    echo json_encode([
        "success" => false,
        "message" => "change tidak boleh 0"
    ]);
    exit;
}

// Kalau tambah stok, harga/unit wajib ada
if ($change > 0 && $unit_price <= 0) {
    echo json_encode([
        "success" => false,
        "message" => "unit_price wajib diisi saat tambah stok"
    ]);
    exit;
}

// =====================================================
// GET ITEM
// =====================================================

$get = $conn->prepare("
    SELECT * 
    FROM item 
    WHERE id_item = ? AND id_user = ?
    LIMIT 1
");

if (!$get) {
    echo json_encode([
        "success" => false,
        "message" => "Prepare select item failed",
        "error" => $conn->error
    ]);
    exit;
}

$get->bind_param("ii", $id_item, $id_user);
$get->execute();

$item = $get->get_result()->fetch_assoc();

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

// =====================================================
// CALCULATE STOCK
// =====================================================

$currentStock = (int)$item['stok'];
$newStock = $currentStock + $change;

if ($newStock < 0) {
    $newStock = 0;
}

// =====================================================
// UPDATE ITEM STOCK
// Kalau restock:
// - quantity/stok naik
// - price di item jadi harga terakhir per unit
//
// Kalau minus:
// - quantity/stok turun
// - price tidak berubah
// =====================================================

if ($change > 0) {
    $update = $conn->prepare("
        UPDATE item 
        SET quantity = ?, stok = ?, price = ?
        WHERE id_item = ? AND id_user = ?
    ");

    if (!$update) {
        echo json_encode([
            "success" => false,
            "message" => "Prepare update stock failed",
            "error" => $conn->error
        ]);
        exit;
    }

    $update->bind_param(
        "iidii",
        $newStock,
        $newStock,
        $unit_price,
        $id_item,
        $id_user
    );
} else {
    $update = $conn->prepare("
        UPDATE item 
        SET quantity = ?, stok = ?
        WHERE id_item = ? AND id_user = ?
    ");

    if (!$update) {
        echo json_encode([
            "success" => false,
            "message" => "Prepare update stock failed",
            "error" => $conn->error
        ]);
        exit;
    }

    $update->bind_param(
        "iiii",
        $newStock,
        $newStock,
        $id_item,
        $id_user
    );
}

if (!$update->execute()) {
    echo json_encode([
        "success" => false,
        "message" => "Stok gagal diupdate",
        "error" => $update->error
    ]);
    exit;
}

// =====================================================
// RECEIPT + STATISTICS
// Hanya kalau tambah stok.
// Kalau kurang stok, tidak masuk pengeluaran.
// =====================================================

$receiptResult = null;

if ($change > 0) {
    $receiptResult = createReceiptItem(
        $conn,
        $id_user,
        $id_item,
        $item['id_category'],
        $item['name'],
        $change,
        $unit_price,
        'Restock'
    );

    if (!$receiptResult['success']) {
        echo json_encode([
            "success" => false,
            "message" => "Stok berhasil diupdate, tapi gagal masuk receipt/statistik",
            "receipt_error" => $receiptResult
        ]);
        exit;
    }
}

// =====================================================
// GET UPDATED ITEM
// =====================================================

$getNew = $conn->prepare("
    SELECT * 
    FROM item 
    WHERE id_item = ? AND id_user = ?
    LIMIT 1
");

if (!$getNew) {
    echo json_encode([
        "success" => false,
        "message" => "Prepare get updated item failed",
        "error" => $conn->error
    ]);
    exit;
}

$getNew->bind_param("ii", $id_item, $id_user);
$getNew->execute();

$updatedItem = $getNew->get_result()->fetch_assoc();

if (!$updatedItem) {
    echo json_encode([
        "success" => false,
        "message" => "Stok berhasil diupdate, tapi data terbaru tidak ditemukan"
    ]);
    exit;
}

// =====================================================
// NOTIFICATION
// =====================================================

syncItemNotifications($conn, $updatedItem);

// =====================================================
// SHOPPING LIST MATCH
// Hanya kalau restock / tambah stok.
// Contoh:
// shopping list item = susu
// item restock = Dancow
// product_alias: dancow -> susu
// maka shopping_list_items.is_bought = 1
// =====================================================

$shoppingMatch = null;

if ($change > 0) {
    $shoppingMatch = markShoppingListIfMatched(
        $conn,
        $id_user,
        $item['name']
    );
}

// =====================================================
// RESPONSE
// =====================================================

echo json_encode([
    "success" => true,
    "message" => "Stok berhasil diupdate",
    "data" => $updatedItem,
    "receipt" => $receiptResult,
    "shopping_match" => $shoppingMatch
]);
exit;