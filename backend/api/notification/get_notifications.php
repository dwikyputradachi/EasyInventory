<?php
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/auth_middleware.php';

$user = authenticate();
$id_user = (int)$user['id_user'];

$db = getDB();

$sql = "SELECT 
            n.*
        FROM notification n
        INNER JOIN item i
            ON n.id_item = i.id_item
        WHERE n.is_read = 0
        AND i.id_user = ?
        ORDER BY n.created_at DESC";

$stmt = $db->prepare($sql);
$stmt->bind_param("i", $id_user);
$stmt->execute();

$result = $stmt->get_result();
$data = [];

while ($row = $result->fetch_assoc()) {
    $data[] = $row;
}

$db->close();

success($data, "Notifications loaded");