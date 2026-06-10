<?php
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') error('Method not allowed', 405);

$body = bodyJson();
$name  = trim($body['name']  ?? '');
$email = trim($body['email'] ?? '');
$pass  = trim($body['password'] ?? '');

if (!$name || !$email || !$pass)   error('Name, email, and password are required');
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) error('Invalid email format');
if (strlen($pass) < 8)             error('Password must be at least 8 characters');

$db = getDB();

// Cek email sudah terdaftar
$stmt = $db->prepare('SELECT id_user FROM users WHERE email = ?');
$stmt->bind_param('s', $email);
$stmt->execute();
if ($stmt->get_result()->num_rows > 0) error('Email already registered');

$hash  = password_hash($pass, PASSWORD_BCRYPT);
$token = bin2hex(random_bytes(32));

$stmt = $db->prepare('INSERT INTO users (name, email, password, token) VALUES (?, ?, ?, ?)');
$stmt->bind_param('ssss', $name, $email, $hash, $token);
$stmt->execute();
$db->close();

success(['token' => $token, 'name' => $name, 'email' => $email], 'Register successful');
