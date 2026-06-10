<?php
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/auth_middleware.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    error('Method not allowed', 405);
}

$user = authenticate();
$body = bodyJson();

$name  = trim($body['name'] ?? '');
$email = trim($body['email'] ?? '');

if (!$name || !$email) {
    error('Name and email are required', 400);
}

$db = getDB();

$stmt = $db->prepare('UPDATE users SET name = ?, email = ? WHERE id_user = ?');
$stmt->bind_param('ssi', $name, $email, $user['id_user']);
$stmt->execute();

$db->close();

success([
    'id_user' => $user['id_user'],
    'name'    => $name,
    'email'   => $email,
], 'Profile updated');