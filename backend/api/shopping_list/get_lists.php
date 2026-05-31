<?php
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/auth_middleware.php';

$user = authenticate();
$db   = getDB();

$stmt = $db->prepare('SELECT id_shopping_list, title, month, year, status, created_at FROM shopping_lists WHERE id_user = ? ORDER BY created_at DESC');
$stmt->bind_param('i', $user['id_user']);
$stmt->execute();
$lists = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);

foreach ($lists as &$list) {
    $s = $db->prepare('SELECT id_shopping_item, name_item, quantity, unit, is_bought FROM shopping_list_items WHERE id_shopping_list = ?');
    $s->bind_param('i', $list['id_shopping_list']);
    $s->execute();
    $list['items'] = $s->get_result()->fetch_all(MYSQLI_ASSOC);
}

$db->close();
success($lists);