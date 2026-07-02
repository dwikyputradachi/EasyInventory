<?php

header("Content-Type: application/json");

require_once "../config/cors.php";
require_once "../config/database.php";

$conn = getDB();

$data = json_decode(file_get_contents("php://input"), true);

if (
    !isset($data["email"]) ||
    !isset($data["otp"]) ||
    !isset($data["purpose"])
) {
    echo json_encode([
        "success" => false,
        "message" => "Email, OTP, dan purpose wajib diisi"
    ]);
    exit;
}

$email = trim($data["email"]);
$otp = trim($data["otp"]);
$purpose = trim($data["purpose"]);

// Cari OTP
$stmt = $conn->prepare("
SELECT *
FROM password_resets
WHERE email=?
AND otp=?
AND purpose=?
LIMIT 1
");

$stmt->bind_param("sss", $email, $otp, $purpose);
$stmt->execute();

$result = $stmt->get_result();

if ($result->num_rows == 0) {
    echo json_encode([
        "success" => false,
        "message" => "OTP salah"
    ]);
    exit;
}

$row = $result->fetch_assoc();

if (strtotime($row["expired_at"]) < time()) {

    echo json_encode([
        "success" => false,
        "message" => "OTP sudah kadaluarsa"
    ]);
    exit;
}

// Jika registrasi, verifikasi email
if ($purpose == "register") {

    $update = $conn->prepare("
    UPDATE users
    SET email_verified = 1
    WHERE email = ?
    ");

    $update->bind_param("s", $email);
    $update->execute();

    if ($update->affected_rows == 0) {

        echo json_encode([
            "success" => false,
            "message" => "Gagal mengubah status verifikasi email"
        ]);
        exit;
    }
}

// Hapus OTP
$delete = $conn->prepare("
DELETE FROM password_resets
WHERE email=?
AND purpose=?
");

$delete->bind_param("ss", $email, $purpose);
$delete->execute();

echo json_encode([
    "success" => true,
    "message" => "OTP berhasil diverifikasi"
]);