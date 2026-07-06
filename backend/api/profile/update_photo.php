<?php
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/auth_middleware.php';

ini_set('display_errors', 0);
error_reporting(E_ALL);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    error('Method not allowed', 405);
}

$user = authenticate();

if (!isset($_FILES['photo'])) {
    error('Photo is required', 400);
}

$file = $_FILES['photo'];

if ($file['error'] !== UPLOAD_ERR_OK) {
    error('Upload failed', 400);
}

$allowed = ['image/jpeg', 'image/png', 'image/jpg', 'image/webp'];
$fileMime = mime_content_type($file['tmp_name']);
if (!in_array($fileMime, $allowed) && !in_array($file['type'], $allowed)) {
    error('Only JPG, PNG, and WEBP are allowed', 400);
}

$uploadDir = __DIR__ . '/../uploads/profile/';

if (!is_dir($uploadDir)) {
    if (!@mkdir($uploadDir, 0777, true) && !is_dir($uploadDir)) {
        error('Failed to create upload directory on server', 500);
    }
}

$ext = pathinfo($file['name'], PATHINFO_EXTENSION);
$fileName = 'profile_' . $user['id_user'] . '_' . time() . '.' . $ext;
$targetPath = $uploadDir . $fileName;

if (!move_uploaded_file($file['tmp_name'], $targetPath)) {
    error('Failed to save photo to server folder', 500);
}

$photoPath = 'api/uploads/profile/' . $fileName;

$db = getDB();
$stmt = $db->prepare('UPDATE users SET profile_photo = ? WHERE id_user = ?');
$stmt->bind_param('si', $photoPath, $user['id_user']);
$stmt->execute();
$db->close();

success([
    'profile_photo' => $photoPath,
], 'Profile photo uploaded');
