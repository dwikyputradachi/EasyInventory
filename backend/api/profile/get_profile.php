<?php
require_once __DIR__ . '/../config/auth_middleware.php';
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') error('Method not allowed', 405);

$user = authenticate();
$db = getDB();

success([
    'id_user' => $user['id_user'],
    'name' => $user['name'],
    'email' => $user['email'],
    'profile_photo' => $user['profile_photo'] ?? null,
], 'Profile loaded');