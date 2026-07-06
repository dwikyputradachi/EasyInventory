<?php
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/auth_middleware.php';

$user = authenticate();
$id_user = (int)$user['id_user'];

$db = getDB();

$sql = "SELECT 
    c.id_category,
    c.name_category,
    COUNT(i.id_item) AS items_count,
    GROUP_CONCAT(i.name SEPARATOR ', ') AS items_name
FROM category c
LEFT JOIN item i 
    ON c.id_category = i.id_category 
    AND i.id_user = ?
GROUP BY c.id_category, c.name_category
ORDER BY c.id_category ASC";

$stmt = $db->prepare($sql);
$stmt->bind_param("i", $id_user);
$stmt->execute();

$result = $stmt->get_result();
$data = [];

while ($row = $result->fetch_assoc()) {
    $data[] = $row;
}

$db->close();

success($data, "Categories loaded");