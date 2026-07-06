<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/auth_middleware.php';
require_once __DIR__ . '/../config/response.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') error('Method not allowed', 405);

$user = authenticate();
$body = bodyJson();
$oldPassword = $body['old_password'] ?? '';
$newPassword = $body['new_password'] ?? '';

if (!$oldPassword || !$newPassword) error('Old and new passwords are required', 400);

if (strlen($newPassword) < 6) error('New password must be at least 6 characters long', 400);
$db = getDB();

$stmt = $db->prepare('SELECT password FROM user WHERE id_user = ?');
$stmt->bind_param('i', $user['id_user']);
$stmt->execute();

$row = $stmt->get_result()->fetch_assoc();

if (!$row || !password_verify($oldPassword, $row['password'])) {
    $db->close();
    error('Old password is incorrect', 400);
}

$newHash = password_hash($newPassword, PASSWORD_DEFAULT);

$stmt = $db->prepare('UPDATE users SET password = ? WHERE id_user = ?');
$stmt->bind_param('si', $newHash, $user['id_user']);
$stmt->execute();

$db->close();

success(null, 'Password changed successfully');