<?php

require_once __DIR__ . "/../config/response.php";
require_once __DIR__ . "/../config/database.php";
require_once __DIR__ . "/../config/auth_middleware.php";

authenticate();

$db = getDB();

$query = "SELECT id_category, name_category FROM category ORDER BY name_category";
$result = $db->query($query);

$data = [];

while ($row = $result->fetch_assoc()) {
    $data[] = $row;
}

$db->close();

success($data, "Categories loaded");