<?php

include_once '../config/response.php';
include_once '../config/database.php';

/** @var mysqli $conn */

$id = $_GET['id'] ?? null;

if (!$id) {
    echo json_encode([
        "success" => false,
        "message" => "id notification wajib diisi"
    ]);
    exit;
}

$check = $conn->prepare("SELECT * FROM notification WHERE id_notification = ?");
$check->bind_param("i", $id);
$check->execute();

if ($check->get_result()->num_rows === 0) {
    http_response_code(404);
    echo json_encode([
        "success" => false,
        "message" => "Notification not found"
    ]);
    exit;
}

$stmt = $conn->prepare("UPDATE notification SET is_read = 1 WHERE id_notification = ?");
$stmt->bind_param("i", $id);
$stmt->execute();

echo json_encode([
    "success" => true,
    "message" => "Notification deleted from list"
]);