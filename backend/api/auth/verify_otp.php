<?php

header("Content-Type: application/json");
ini_set('display_errors', 0); 
error_reporting(E_ALL);

require_once "../config/cors.php";
require_once "../config/database.php";
require_once "../config/auth_middleware.php";

$authUser = null;
if (isset($_SERVER['REQUEST_METHOD']) && $_SERVER['REQUEST_METHOD'] == 'POST') {
    $rawInput = file_get_contents("php://input");
    $checkData = json_decode($rawInput, true);
    
    if (isset($checkData["purpose"]) && $checkData["purpose"] == "change_email") {
        $authUser = authenticate(); 
    }
}

$conn = getDB();
$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data["email"]) || !isset($data["otp"]) || !isset($data["purpose"])) {
    echo json_encode(["success" => false, "message" => "Data tidak lengkap"]);
    exit;
}

$email = trim($data["email"]); 
$otp = trim($data["otp"]);
$purpose = trim($data["purpose"]);

// Cari data OTP
$stmt = $conn->prepare("SELECT * FROM password_resets WHERE email = ? AND purpose = ? ORDER BY expired_at DESC LIMIT 1");
$stmt->bind_param("ss", $email, $purpose);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows == 0) {
    echo json_encode(["success" => false, "message" => "Data OTP tidak ditemukan di database"]);
    exit;
}

$row = $result->fetch_assoc();

if (trim($row["otp"]) !== $otp) {
    echo json_encode(["success" => false, "message" => "OTP salah (Kode tidak cocok)"]);
    exit;
}

// EKSEKUSI PROSES GANTI EMAIL
if ($purpose == "change_email") {
    if (!$authUser) {
        echo json_encode(["success" => false, "message" => "Sesi login tidak valid"]);
        exit;
    }

    $update = $conn->prepare("UPDATE users SET email = ? WHERE id_user = ?");
    $update->bind_param("si", $email, $authUser["id_user"]);
    $update->execute();
}

// EKSEKUSI PROSES REGISTER VERIFIED
if ($purpose == "register") {
    $update = $conn->prepare("UPDATE users SET email_verified = 1 WHERE email = ?");
    $update->bind_param("s", $email);
    $update->execute();
}

// Hapus token OTP lama
$delete = $conn->prepare("DELETE FROM password_resets WHERE email = ?");
$delete->bind_param("s", $email);
$delete->execute();

echo json_encode(["success" => true, "message" => "Email berhasil diperbarui!"]);
