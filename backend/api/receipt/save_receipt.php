<?php
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/auth_middleware.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') error('Method not allowed', 405);

$user  = authenticate();
$body  = bodyJson();
$rname = trim($body['receipt_name'] ?? '');
$items = $body['items'] ?? [];

if (!$rname || empty($items)) error('receipt_name and items are required');

$db = getDB();
$db->begin_transaction();

try {
    // 1. Simpan receipt
    $stmt = $db->prepare('INSERT INTO receipt (id_user, name) VALUES (?, ?)');
    $stmt->bind_param('is', $user['id_user'], $rname);
    $stmt->execute();
    $id_receipt = $db->insert_id;

    foreach ($items as $it) {
        $name   = trim($it['name']         ?? '');
        $price  = (float)($it['price']     ?? 0);
        $qty    = (int)($it['quantity']    ?? 1);
        $id_cat = (int)($it['id_category'] ?? 0);

        if (!$name) continue;

        // 2. Simpan ke receipt_item
        $s = $db->prepare('INSERT INTO receipt_item (id_receipt, id_category, name, quantity, price) VALUES (?, ?, ?, ?, ?)');
        $s->bind_param('iisid', $id_receipt, $id_cat, $name, $qty, $price);
        $s->execute();

        // 3. Cek item di inventory
        $like = '%' . $name . '%';
        $s = $db->prepare('SELECT id_item, stok FROM item WHERE id_user = ? AND name LIKE ?');
        $s->bind_param('is', $user['id_user'], $like);
        $s->execute();
        $existing = $s->get_result()->fetch_assoc();

        if ($existing) {
            $newStok = $existing['stok'] + $qty;
            $s = $db->prepare('UPDATE item SET stok = ? WHERE id_item = ?');
            $s->bind_param('ii', $newStok, $existing['id_item']);
            $s->execute();
        } else {
            $s = $db->prepare('INSERT INTO item (id_user, id_category, name, quantity, stok, price) VALUES (?, ?, ?, ?, ?, ?)');
            $s->bind_param('iisiid', $user['id_user'], $id_cat, $name, $qty, $qty, $price);
            $s->execute();
        }

        // 4. Cocokkan dengan shopping list
        $s = $db->prepare('
            UPDATE shopping_list_items sli
            JOIN shopping_lists sl ON sli.id_shopping_list = sl.id_shopping_list
            SET sli.is_bought = 1, sli.matched_item_name = ?
            WHERE sl.id_user = ? AND sli.is_bought = 0 AND sli.name_item LIKE ?
        ');
        $s->bind_param('sis', $name, $user['id_user'], $like);
        $s->execute();
    }

    $db->commit();
    $db->close();
    success(['id_receipt' => $id_receipt, 'total_items' => count($items)], 'Receipt saved');

} catch (Exception $e) {
    $db->rollback();
    $db->close();
    error('Failed to save receipt: ' . $e->getMessage(), 500);
}