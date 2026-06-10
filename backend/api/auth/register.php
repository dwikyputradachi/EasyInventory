<?php

include_once '../config/response.php';
include_once '../config/database.php';

/** @var mysqli $conn */

$data = json_decode(file_get_contents("php://input"), true);

$name = $data['name'] ?? null;
$email = $data['email'] ?? null;
$password = $data['password'] ?? null;
$role = $data['role'] ?? 'user';

if (!$name || !$email || !$password) {
    echo json_encode([
        "success" => false,
        "message" => "Name, email, dan password wajib diisi"
    ]);
    exit;
}
$check = $conn->prepare("SELECT id_user FROM users WHERE email = ? LIMIT 1");
$check->bind_param("s", $email);
$check->execute();

if ($check->get_result()->num_rows > 0) {
    echo json_encode([
        "success" => false,
        "message" => "Email sudah terdaftar"
    ]);
    exit;
}

$hashedPassword = password_hash($password, PASSWORD_DEFAULT);

$stmt = $conn->prepare("
    INSERT INTO users (name, email, password, foto_profil, role, created_at, updated_at)
    VALUES (?, ?, ?, NULL, ?, NOW(), NOW())
");

$stmt->bind_param("ssss", $name, $email, $hashedPassword, $role);

if (!$stmt->execute()) {
    echo json_encode([
        "success" => false,
        "message" => "Register gagal: " . $stmt->error
    ]);
    exit;
}

$id_user = $conn->insert_id;

$get = $conn->prepare("
    SELECT id_user, name, email, foto_profil, role, created_at, updated_at
    FROM users
    WHERE id_user = ?
");

$get->bind_param("i", $id_user);
$get->execute();

echo json_encode([
    "success" => true,
    "message" => "Register berhasil",
    "data" => $get->get_result()->fetch_assoc()
]);