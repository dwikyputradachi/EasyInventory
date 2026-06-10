<?php
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/auth_middleware.php';

$user   = authenticate();
$db     = getDB();
$notifs = [];

// 1. Expired / hampir expired (≤ 3 hari)
$stmt = $db->prepare('
    SELECT name, expired_date, DATEDIFF(expired_date, CURDATE()) AS diff
    FROM item WHERE id_user = ? AND DATEDIFF(expired_date, CURDATE()) <= 3
    ORDER BY expired_date ASC
');
$stmt->bind_param('i', $user['id_user']);
$stmt->execute();
foreach ($stmt->get_result()->fetch_all(MYSQLI_ASSOC) as $row) {
    $diff = (int)$row['diff'];
    $notifs[] = [
        'type'    => $diff < 0 ? 'expired' : 'expiring_soon',
        'title'   => $diff < 0 ? 'Item Expired' : 'Hampir Expired',
        'message' => $diff < 0
            ? "{$row['name']} sudah expired."
            : "{$row['name']} akan expired dalam $diff hari.",
    ];
}

// 2. Low stock (stok ≤ 2)
$stmt = $db->prepare('SELECT name, stok FROM item WHERE id_user = ? AND stok <= 2 AND stok >= 0');
$stmt->bind_param('i', $user['id_user']);
$stmt->execute();
foreach ($stmt->get_result()->fetch_all(MYSQLI_ASSOC) as $row) {
    $notifs[] = [
        'type'    => 'low_stock',
        'title'   => 'Stok Menipis',
        'message' => "{$row['name']} tersisa {$row['stok']} stok.",
    ];
}

// 3. Shopping list item belum dibeli
$stmt = $db->prepare('
    SELECT sli.name_item FROM shopping_list_items sli
    JOIN shopping_lists sl ON sli.id_shopping_list = sl.id_shopping_list
    WHERE sl.id_user = ? AND sli.is_bought = 0
');
$stmt->bind_param('i', $user['id_user']);
$stmt->execute();
$unbought = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
if (!empty($unbought)) {
    $notifs[] = [
        'type'    => 'shopping_reminder',
        'title'   => 'Shopping List',
        'message' => count($unbought) . ' item di shopping list belum dibeli.',
    ];
}

// 4. Budget alert
$stmt = $db->prepare('
    SELECT SUM(ri.price * ri.quantity) AS total
    FROM receipt r JOIN receipt_item ri ON r.id_receipt = ri.id_receipt
    WHERE r.id_user = ? AND MONTH(r.created_at) = MONTH(NOW()) AND YEAR(r.created_at) = YEAR(NOW())
');
$stmt->bind_param('i', $user['id_user']);
$stmt->execute();
$thisMonth = (float)($stmt->get_result()->fetch_assoc()['total'] ?? 0);

$stmt = $db->prepare('
    SELECT AVG(t.total) AS avg FROM (
        SELECT SUM(ri.price * ri.quantity) AS total
        FROM receipt r JOIN receipt_item ri ON r.id_receipt = ri.id_receipt
        WHERE r.id_user = ?
          AND NOT (MONTH(r.created_at) = MONTH(NOW()) AND YEAR(r.created_at) = YEAR(NOW()))
        GROUP BY YEAR(r.created_at), MONTH(r.created_at)
    ) t
');
$stmt->bind_param('i', $user['id_user']);
$stmt->execute();
$avg = (float)($stmt->get_result()->fetch_assoc()['avg'] ?? 0);

if ($avg > 0 && $thisMonth > ($avg * 0.92)) {
    $notifs[] = [
        'type'    => 'budget_alert',
        'title'   => 'Budget Terlampaui',
        'message' => 'Pengeluaran bulan ini sudah melebihi rekomendasi budget.',
    ];
}

$db->close();
success($notifs);