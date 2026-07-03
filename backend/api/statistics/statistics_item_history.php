<?php
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/auth_middleware.php';

$user  = authenticate();

$year  = (int)($_GET['year'] ?? date('Y'));
$month = (int)($_GET['month'] ?? date('m'));

$db = getDB();

$stmt = $db->prepare("
SELECT
    ri.name AS item_name,
    SUM(ri.quantity) AS total_qty,
    AVG(ri.price) AS unit_price,
    SUM(ri.quantity * ri.price) AS total_spending,
    c.name_category
FROM receipt r
JOIN receipt_item ri
    ON r.id_receipt = ri.id_receipt
LEFT JOIN category c
    ON ri.id_category = c.id_category
WHERE r.id_user = ?
AND YEAR(r.created_at) = ?
AND MONTH(r.created_at) = ?
GROUP BY LOWER(TRIM(ri.name))
ORDER BY total_spending DESC
");

$stmt->bind_param(
    'iii',
    $user['id_user'],
    $year,
    $month
);

$stmt->execute();

$items = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);

$db->close();

success([
    'items' => $items
]);