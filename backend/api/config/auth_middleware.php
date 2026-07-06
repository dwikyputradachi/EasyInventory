<?php
require_once __DIR__ . '/database.php';
require_once __DIR__ . '/response.php';

function getBearerToken() {
    $headers = function_exists('getallheaders') ? getallheaders() : [];

    $auth = '';

    foreach ($headers as $key => $value) {
        if (strtolower($key) === 'authorization') {
            $auth = $value;
            break;
        }
    }

    if (!$auth) {
        $auth = $_SERVER['HTTP_AUTHORIZATION']
            ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION']
            ?? '';
    }

    if (preg_match('/Bearer\s+(\S+)/i', $auth, $matches)) {
        return trim($matches[1]);
    }

    return null;
}

function authenticate() {
    $token = getBearerToken();

    if (!$token) {
        error('Unauthorized: Token not provided', 401);
    }

    $db = getDB();

    $stmt = $db->prepare('SELECT id_user, name, email, profile_photo FROM users WHERE token = ?');
    $stmt->bind_param('s', $token);
    $stmt->execute();

    $user = $stmt->get_result()->fetch_assoc();

    $stmt->close();
    $db->close();

    if (!$user) {
        error('Unauthorized: Invalid token', 401);
    }

    return $user;
}