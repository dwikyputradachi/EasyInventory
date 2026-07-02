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

$id_category  = $_GET['id_category'] ?? ($data['id_category'] ?? null);
$name         = trim($data['name'] ?? '');
$quantity     = $data['quantity'] ?? null;
$stok         = $quantity;
$price        = $data['price'] ?? 0;
$unit         = $data['unit'] ?? null;
$barcode      = $data['barcode'] ?? null;
$expired_date = $data['expired_date'] ?? null;

if ($expired_date === '') {
    $expired_date = null;
}

// =====================================================
// AUTO CATEGORY
// Tetap pakai ocr_keywords untuk kategori
// Bukan product_alias
// =====================================================

if (!$id_category && !empty($name)) {
    $input = strtolower(trim($name));
    $id_category = null;

    $catQuery = $conn->prepare("
        SELECT id_category, name_category, ocr_keywords
        FROM category
    ");

    if (!$catQuery) {
        echo json_encode([
            "success" => false,
            "message" => "Prepare category failed",
            "error" => $conn->error
        ]);
        exit;
    }

    $catQuery->execute();
    $result = $catQuery->get_result();

    while ($row = $result->fetch_assoc()) {
        $keywords = strtolower($row['ocr_keywords'] ?? '');
        $keywordList = array_map('trim', explode(',', $keywords));

        foreach ($keywordList as $kw) {
            if ($kw !== '' && strpos($input, $kw) !== false) {
                $id_category = $row['id_category'];
                break 2;
            }
        }
    }

    // fallback ke Others kalau tidak ada keyword yang cocok
    if (!$id_category) {
        $others = $conn->prepare("
            SELECT id_category 
            FROM category 
            WHERE name_category = 'Others'
            LIMIT 1
        ");

        if (!$others) {
            echo json_encode([
                "success" => false,
                "message" => "Prepare Others category failed",
                "error" => $conn->error
            ]);
            exit;
        }

        $others->execute();
        $othersResult = $others->get_result()->fetch_assoc();

        $id_category = $othersResult['id_category'] ?? null;
    }
}

// =====================================================
// VALIDATION
// =====================================================

if (!$id_category || !$id_user || !$name || $quantity === null || !$unit) {
    echo json_encode([
        "success" => false,
        "message" => "Data wajib belum lengkap",
        "debug" => [
            "id_category" => $id_category,
            "id_user" => $id_user,
            "name" => $name,
            "quantity" => $quantity,
            "unit" => $unit,
            "data" => $data
        ]
    ]);
    exit;
}

$id_category = (int)$id_category;
$quantity = (int)$quantity;
$stok = (int)$stok;
$price = (float)$price;

if ($quantity <= 0) {
    echo json_encode([
        "success" => false,
        "message" => "Quantity harus lebih dari 0"
    ]);
    exit;
}

if ($price <= 0) {
    echo json_encode([
        "success" => false,
        "message" => "Price wajib diisi agar masuk statistik pengeluaran"
    ]);
    exit;
}

// =====================================================
// INSERT ITEM
// =====================================================

$sql = "
    INSERT INTO item 
    (id_category, id_user, name, quantity, stok, price, unit, barcode, expired_date)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
";

$stmt = $conn->prepare($sql);

if (!$stmt) {
    echo json_encode([
        "success" => false,
        "message" => "Prepare insert item failed",
        "error" => $conn->error
    ]);
    exit;
}

$stmt->bind_param(
    "iisiidsss",
    $id_category,
    $id_user,
    $name,
    $quantity,
    $stok,
    $price,
    $unit,
    $barcode,
    $expired_date
);

if (!$stmt->execute()) {
    echo json_encode([
        "success" => false,
        "message" => "Produk gagal ditambahkan",
        "error" => $stmt->error
    ]);
    exit;
}

$id_item = $conn->insert_id;

// =====================================================
// INSERT RECEIPT + RECEIPT_ITEM
// Untuk statistik user
// receipt_item.price = total harga
// total = quantity * unit price
// =====================================================

$receiptResult = createReceiptItem(
    $conn,
    $id_user,
    $id_item,
    $id_category,
    $name,
    $quantity,
    $price,
    'Manual Add Product'
);

if (!$receiptResult['success']) {
    echo json_encode([
        "success" => false,
        "message" => "Produk berhasil ditambahkan, tapi gagal masuk receipt/statistik",
        "receipt_error" => $receiptResult
    ]);
    exit;
}

// =====================================================
// GET NEW ITEM
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
        "message" => "Prepare get item failed",
        "error" => $conn->error
    ]);
    exit;
}

$get->bind_param("ii", $id_item, $id_user);
$get->execute();

$item = $get->get_result()->fetch_assoc();

if (!$item) {
    echo json_encode([
        "success" => false,
        "message" => "Produk berhasil ditambahkan, tapi data tidak ditemukan ulang"
    ]);
    exit;
}

// =====================================================
// NOTIFICATION
// =====================================================

syncItemNotifications($conn, $item);

// =====================================================
// SHOPPING LIST MATCH
// Contoh:
// shopping list item = susu
// product masuk = Dancow
// product_alias: dancow -> susu
// maka shopping_list_items.is_bought = 1
// =====================================================

$shoppingMatch = markShoppingListIfMatched($conn, $id_user, $name);

// =====================================================
// RESPONSEkdada aa
// ===================================================

http_response_code(201);
echo json_encode([
    "success" => true,
    "message" => "Produk berhasil ditambahkan",
    "data" => $item,
    "receipt" => $receiptResult,
    "shopping_match" => $shoppingMatch
]);
exit;