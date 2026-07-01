<?php

include_once __DIR__ . '/../config/response.php';
include_once __DIR__ . '/../config/database.php';

$conn = getDB(); 

$barcode = $_GET['barcode'] ?? '';

$id_user = $_GET['id_user'] ?? ''; // TAMBAH INI


if ($barcode === '') {

    echo json_encode([
        "success" => false,
        "message" => "Barcode wajib diisi"
    ]);

    exit;
}


$sql = "
SELECT *
FROM item
WHERE barcode = ?
AND id_user = ?
ORDER BY id_item DESC
LIMIT 1
";


$stmt = $conn->prepare($sql);


$stmt->bind_param(
    "si",
    $barcode,
    $id_user
);


$stmt->execute();


$result = $stmt->get_result();


if ($result->num_rows === 0) {

    http_response_code(404);

    echo json_encode([
        "success" => false,
        "message" => "Barcode belum ditemukan"
    ]);

    exit;

}


echo json_encode([
    "success" => true,
    "data" => $result->fetch_assoc()
]);