<?php

header("Content-Type: application/json");

require_once "../config/database.php";
require_once "../config/cors.php";
$conn = getDB();

$data = json_decode(file_get_contents("php://input"), true);

if (
    !isset($data["email"]) ||
    !isset($data["password"])
) {
    echo json_encode([
        "success" => false,
        "message" => "Email dan password wajib diisi"
    ]);
    exit;
}

$email = trim($data["email"]);
$password = trim($data["password"]);

if (strlen($password) < 6) {
    echo json_encode([
        "success" => false,
        "message" => "Password minimal 6 karakter"
    ]);
    exit;
}

$hashPassword = password_hash(
    $password,
    PASSWORD_DEFAULT
);

$stmt = $conn->prepare("
UPDATE users
SET password=?
WHERE email=?
");

$stmt->bind_param(
    "ss",
    $hashPassword,
    $email
);

if ($stmt->execute()) {

    $delete = $conn->prepare("
    DELETE FROM password_resets
    WHERE email=?
    ");

    $delete->bind_param(
        "s",
        $email
    );

    $delete->execute();

    echo json_encode([
        "success" => true,
        "message" => "Password berhasil diubah"
    ]);

} else {

    echo json_encode([
        "success" => false,
        "message" => "Gagal mengubah password"
    ]);

}