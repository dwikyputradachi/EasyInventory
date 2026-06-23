<?php
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/auth_middleware.php';
require_once __DIR__ . '/../config/notification_helper.php';

header('Content-Type: application/json');

$user = authenticate();
$id_user = (int)$user['id_user'];

$conn = getDB();

$data = json_decode(file_get_contents("php://input"), true);

$id_item = isset($data['id_item']) ? (int)$data['id_item'] : null;
$change  = isset($data['change']) ? (int)$data['change'] : null;

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

$get = $conn->prepare("
    SELECT * FROM item 
    WHERE id_item = ? AND id_user = ?
    LIMIT 1
");

if (!$get) {
    echo json_encode([
        "success" => false,
        "message" => "Prepare select failed",
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

$currentStock = (int)$item['stok'];
$newStock = $currentStock + $change;

if ($newStock < 0) {
    $newStock = 0;
}

$update = $conn->prepare("
    UPDATE item 
    SET quantity = ?, stok = ?
    WHERE id_item = ? AND id_user = ?
");

if (!$update) {
    echo json_encode([
        "success" => false,
        "message" => "Prepare update failed",
        "error" => $conn->error
    ]);
    exit;
}

$update->bind_param("iiii", $newStock, $newStock, $id_item, $id_user);

if (!$update->execute()) {
    echo json_encode([
        "success" => false,
        "message" => "Stok gagal diupdate",
        "error" => $update->error
    ]);
    exit;
}

$getNew = $conn->prepare("
    SELECT * FROM item 
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

syncItemNotifications($conn, $updatedItem);

echo json_encode([
    "success" => true,
    "message" => "Stok berhasil diupdate",
    "data" => $updatedItem
]);
exit;