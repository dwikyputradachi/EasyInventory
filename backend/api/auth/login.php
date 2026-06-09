<?php

include_once '../config/response.php';
include_once '../config/database.php';

/** @var mysqli $conn */

$data = json_decode(file_get_contents("php://input"), true);

$email = $data['email'] ?? null;
$password = $data['password'] ?? null;

if (!$email || !$password) {
    echo json_encode([
        "success" => false,
        "message" => "Email dan password wajib diisi"
    ]);
    exit;
}

$stmt = $conn->prepare("
    SELECT id_user, name, email, password, foto_profil, role, created_at, updated_at
    FROM users
    WHERE email = ?
    LIMIT 1
");

$stmt->bind_param("s", $email);
$stmt->execute();

$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode([
        "success" => false,
        "message" => "Email tidak ditemukan"
    ]);
    exit;
}

$user = $result->fetch_assoc();

if (!password_verify($password, $user['password'])) {
    echo json_encode([
        "success" => false,
        "message" => "Password salah"
    ]);
    exit;
}

unset($user['password']);

echo json_encode([
    "success" => true,
    "message" => "Login berhasil",
    "data" => $user
]);