<?php
require_once __DIR__ . '/database.php';

function authenticate() {
    $headers = getallheaders();
    $auth    = $headers['Authorization'] ?? '';

    if (!str_starts_with($auth, 'Bearer ')) {
        error('Unauthorized', 401);
    }

    $token = trim(str_replace('Bearer ', '', $auth));
    $db    = getDB();
    $stmt  = $db->prepare('SELECT id_user, name, email FROM users WHERE token = ?');
    $stmt->bind_param('s', $token);
    $stmt->execute();
    $user = $stmt->get_result()->fetch_assoc();
    $db->close();

    if (!$user) error('Unauthorized', 401);
    return $user;
}
