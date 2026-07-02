<?php

require_once "../config/cors.php";
require_once "../config/database.php";
require "../../vendor/autoload.php";

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

$conn = getDB();

$data = json_decode(file_get_contents("php://input"), true);

if (
    !isset($data["email"]) ||
    !isset($data["purpose"])
) {
    echo json_encode([
        "success" => false,
        "message" => "Email dan purpose wajib diisi"
    ]);
    exit;
}

$email   = trim($data["email"]);
$purpose = trim($data["purpose"]);

if (!in_array($purpose, ["register", "forgot_password"])) {
    echo json_encode([
        "success" => false,
        "message" => "Purpose tidak valid"
    ]);
    exit;
}

if ($purpose == "forgot_password") {

    $stmt = $conn->prepare("
        SELECT id_user, email_verified
        FROM users
        WHERE email = ?
    ");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows == 0) {
        echo json_encode([
            "success" => false,
            "message" => "Email belum terdaftar"
        ]);
        exit;
    }

    $user = $result->fetch_assoc();

    if ($user["email_verified"] == 0) {
        echo json_encode([
            "success" => false,
            "message" => "Email belum diverifikasi"
        ]);
        exit;
    }
}

$otp     = rand(100000, 999999);
$expired = date("Y-m-d H:i:s", strtotime("+5 minutes"));

// --- Transaction: hapus OTP lama + insert OTP baru + kirim email harus all-or-nothing ---
$conn->begin_transaction();

try {

    // hapus OTP lama dengan purpose yang sama
    $delete = $conn->prepare("
        DELETE FROM password_resets
        WHERE email = ?
        AND purpose = ?
    ");
    $delete->bind_param("ss", $email, $purpose);
    $delete->execute();

    $insert = $conn->prepare("
        INSERT INTO password_resets (email, otp, expired_at, purpose)
        VALUES (?, ?, ?, ?)
    ");
    $insert->bind_param("ssss", $email, $otp, $expired, $purpose);
    $insert->execute();

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

    if ($purpose == "register") {
        $mail->Subject = "Verifikasi Email";
        $mail->Body = "
            <h2>Easy Inventory</h2>
            <p>Selamat datang.</p>
            <p>Kode verifikasi email:</p>
            <h1>$otp</h1>
            <p>Berlaku selama 5 menit.</p>
        ";
    } else {
        $mail->Subject = "Reset Password";
        $mail->Body = "
            <h2>Easy Inventory</h2>
            <p>Kode OTP reset password:</p>
            <h1>$otp</h1>
            <p>Berlaku selama 5 menit.</p>
        ";
    }

    // Kalau send() gagal, exception dilempar (karena new PHPMailer(true))
    // sehingga transaction di-rollback di bawah -> tidak ada OTP nyangkut di DB.
    $mail->send();

    $conn->commit();

    echo json_encode([
        "success" => true,
        "message" => "OTP berhasil dikirim"
    ]);

} catch (Exception $e) {

    $conn->rollback();

    echo json_encode([
        "success" => false,
        "message" => "Gagal mengirim OTP: " . $e->getMessage()
    ]);
}