<?php
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';
require_once "../config/cors.php";
if ($_SERVER['REQUEST_METHOD'] !== 'POST') error('Method not allowed', 405);

$body  = bodyJson();
$email = trim($body['email']    ?? '');
$pass  = trim($body['password'] ?? '');

if (!$email || !$pass) error('Email and password are required');

$db   = getDB();
$stmt = $db->prepare('SELECT id_user, name, email, password FROM users WHERE email = ?');
$stmt->bind_param('s', $email);
$stmt->execute();
$user = $stmt->get_result()->fetch_assoc();

if (!$user || !password_verify($pass, $user['password'])) error('Invalid email or password', 401);

// Regenerate token setiap login
$token = bin2hex(random_bytes(32));
$stmt  = $db->prepare('UPDATE users SET token = ? WHERE id_user = ?');
$stmt->bind_param('si', $token, $user['id_user']);
$stmt->execute();
$db->close();

success([
    'token' => $token,
    'id_user' => $user['id_user'],
    'name'  => $user['name'],
    'email' => $user['email'],
], 'Login successful');
