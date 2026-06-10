<?php
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/auth_middleware.php';
require_once __DIR__ . '/../config/notification_helper.php';

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

// AUTO CATEGORY kalau id_category kosong
if (!$id_category && !empty($name)) {
    $input = strtolower(trim($name));
    $id_category = null;

    $catQuery = $conn->prepare("
        SELECT id_category, name_category, ocr_keywords
        FROM category
    ");
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
        $others->execute();
        $othersResult = $others->get_result()->fetch_assoc();

        $id_category = $othersResult['id_category'] ?? null;
    }
}

if (!$id_category || !$id_user || !$name || $quantity === null || !$unit) {
    echo json_encode([
        "success" => false,
        "message" => "Data wajib belum lengkap",
        "debug" => [
            "id_category" => $id_category,
            "id_user" => $id_user,
            "name" => $name,
            "quantity" => $quantity,
            "unit" => $unit
        ]
    ]);
    exit;
}

$sql = "INSERT INTO item 
(id_category, id_user, name, quantity, stok, price, unit, barcode, expired_date)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";

$stmt = $conn->prepare($sql);

if (!$stmt) {
    echo json_encode([
        "success" => false,
        "message" => "Prepare failed",
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

// Low stock notification
if ($stok <= 5) {
    $type = "low_stock";
    $title = $name;
    $message = "Current stock: " . $stok;

    $check = $conn->prepare("
        SELECT id_notification 
        FROM notification 
        WHERE id_item = ? AND type = ? AND is_read = 0 
        LIMIT 1
    ");
    $check->bind_param("is", $id_item, $type);
    $check->execute();

    if ($check->get_result()->num_rows === 0) {
        $insertNotif = $conn->prepare("
            INSERT INTO notification 
            (id_item, title, message, type, is_read) 
            VALUES (?, ?, ?, ?, 0)
        ");
        $insertNotif->bind_param("isss", $id_item, $title, $message, $type);
        $insertNotif->execute();
    }
}

// Expired / near expired notification
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
        $check = $conn->prepare("
            SELECT id_notification 
            FROM notification 
            WHERE id_item = ? AND type = ? AND is_read = 0 
            LIMIT 1
        ");
        $check->bind_param("is", $id_item, $type);
        $check->execute();

        if ($check->get_result()->num_rows === 0) {
            $insertNotif = $conn->prepare("
                INSERT INTO notification 
                (id_item, title, message, type, is_read) 
                VALUES (?, ?, ?, ?, 0)
            ");
            $insertNotif->bind_param("isss", $id_item, $title, $message, $type);
            $insertNotif->execute();
        }
    }
}

$get = $conn->prepare("SELECT * FROM item WHERE id_item = ?");
$get->bind_param("i", $id_item);
$get->execute();
$item = $get->get_result()->fetch_assoc();

syncItemNotifications($conn, $item);

http_response_code(201);
echo json_encode([
    "success" => true,
    "message" => "Produk berhasil ditambahkan",
    "data" => $item
]);