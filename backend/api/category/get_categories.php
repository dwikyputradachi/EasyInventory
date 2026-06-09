<?php

include_once '../config/response.php';
include_once '../config/database.php';

/** @var mysqli $conn */

$id_user = $_GET['id_user'] ?? null;

if (!$id_user) {
    echo json_encode([
        "success" => false,
        "message" => "id_user wajib diisi"
    ]);
    exit;
}

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

$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $id_user);
$stmt->execute();

$result = $stmt->get_result();
$data = [];

while ($row = $result->fetch_assoc()) {
    $data[] = $row;
}

echo json_encode([
    "success" => true,
    "data" => $data
]);