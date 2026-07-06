<?php

require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . "/../vendor/autoload.php";

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    error('Method not allowed', 405);
}

$body = bodyJson();

$name  = trim($body['name']     ?? '');
$email = trim($body['email']    ?? '');
$pass  = trim($body['password'] ?? '');

if (!$name || !$email || !$pass) {
    error('Name, email, and password are required');
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    error('Invalid email format');
}

if (strlen($pass) < 8) {
    error('Password must be at least 8 characters');
}

$db = getDB();

// --- Cek apakah email sudah ada ---
$stmt = $db->prepare("SELECT id_user, email_verified FROM users WHERE email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$existing = $stmt->get_result()->fetch_assoc();

if ($existing) {
    if ((int)$existing['email_verified'] === 1) {
        // Sudah verified -> benar-benar sudah terdaftar, tolak
        error("Email already registered");
    }
    // Belum verified -> row "hantu" dari percobaan register sebelumnya
    // yang gagal kirim OTP. Bersihkan supaya user bisa daftar ulang.
    $delUser = $db->prepare("DELETE FROM users WHERE email = ?");
    $delUser->bind_param("s", $email);
    $delUser->execute();

    $delOtp = $db->prepare("DELETE FROM password_resets WHERE email = ?");
    $delOtp->bind_param("s", $email);
    $delOtp->execute();
}

$password = password_hash($pass, PASSWORD_DEFAULT);
$token    = bin2hex(random_bytes(32));
$role     = "user";
$otp      = rand(100000, 999999);
$expired  = date("Y-m-d H:i:s", strtotime("+5 minutes"));
$purpose  = "register";

// --- Mulai transaction: insert user + otp harus all-or-nothing dengan kirim email ---
$db->begin_transaction();

try {
    $stmt = $db->prepare("
        INSERT INTO users (name, email, password, token, role, email_verified)
        VALUES (?, ?, ?, ?, ?, 0)
    ");
    $stmt->bind_param("sssss", $name, $email, $password, $token, $role);
    $stmt->execute();

    $stmt = $db->prepare("
        INSERT INTO password_resets (email, otp, expired_at, purpose)
        VALUES (?, ?, ?, ?)
    ");
    $stmt->bind_param("ssss", $email, $otp, $expired, $purpose);
    $stmt->execute();

    // --- Kirim email di dalam try yang sama, supaya kegagalan bisa memicu rollback ---
    $mail = new PHPMailer(true);

    $mail->isSMTP();
    $mail->Host       = "smtp.gmail.com";
    $mail->SMTPAuth   = true;
    $mail->Username   = "raymondsilalahi12321@gmail.com";
    $mail->Password   = "rnuqsrtkleagfbsu"; 
    $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
    $mail->Port       = 587;
    $mail->CharSet    = "UTF-8";

    $mail->setFrom("raymondsilalahi12321@gmail.com", "Easy Inventory");
    $mail->addAddress($email);
    $mail->isHTML(true);
    $mail->Subject = "Email Verification";
    $mail->Body = "
        <h2>Easy Inventory</h2>
        <p>Welcome, <b>$name</b></p>
        <p>Your verification code is:</p>
        <h1>$otp</h1>
        <p>This OTP is valid for 5 minutes.</p>
    ";

    // Kalau send() gagal, PHPMailer melempar Exception (karena `new PHPMailer(true)`)
    // sehingga langsung ditangkap di catch di bawah dan transaction di-rollback.
    $mail->send();

    // Semua berhasil -> commit
    $db->commit();

    success([
        "email" => $email,
        "name"  => $name,
    ], "OTP sent successfully");

} catch (Exception $e) {
    // Insert users / password_resets DIBATALKAN kalau email gagal terkirim,
    // jadi tidak ada row "hantu" yang bikin email dianggap sudah terdaftar.
    $db->rollback();

    error("Gagal mengirim OTP, silakan coba lagi. (" . $e->getMessage() . ")");
}