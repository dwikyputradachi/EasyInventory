<?php
require_once __DIR__ . '/../config/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/auth_middleware.php';

$user  = authenticate();
$year  = (int)($_GET['year'] ?? date('Y'));
$month = isset($_GET['month']) ? (int)$_GET['month'] : null;

$db = getDB();

// 1. Spending per bulan dalam 1 tahun
$stmt = $db->prepare('
    SELECT 
        DATE_FORMAT(r.created_at, "%M %Y") AS month,
        MONTH(r.created_at) AS month_num,
        SUM(ri.price * ri.quantity) AS total
    FROM receipt r
    JOIN receipt_item ri ON r.id_receipt = ri.id_receipt
    WHERE r.id_user = ? 
      AND YEAR(r.created_at) = ?
    GROUP BY MONTH(r.created_at), DATE_FORMAT(r.created_at, "%M %Y")
    ORDER BY MONTH(r.created_at) ASC
');
$stmt->bind_param('ii', $user['id_user'], $year);
$stmt->execute();
$monthly = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);

// 2. Total bulan terpilih
$monthTotal = 0;
foreach ($monthly as $m) {
    if ($month !== null && (int)$m['month_num'] === $month) {
        $monthTotal = (int)$m['total'];
    }
}

// 3. Spending per kategori
if ($month !== null) {
    $stmt = $db->prepare('
        SELECT 
            c.name_category AS category,
            SUM(ri.price * ri.quantity) AS total
        FROM receipt r
        JOIN receipt_item ri ON r.id_receipt = ri.id_receipt
        JOIN category c ON ri.id_category = c.id_category
        WHERE r.id_user = ?
          AND YEAR(r.created_at) = ?
          AND MONTH(r.created_at) = ?
        GROUP BY c.id_category, c.name_category
        ORDER BY total DESC
    ');
    $stmt->bind_param('iii', $user['id_user'], $year, $month);
} else {
    $stmt = $db->prepare('
        SELECT 
            c.name_category AS category,
            SUM(ri.price * ri.quantity) AS total
        FROM receipt r
        JOIN receipt_item ri ON r.id_receipt = ri.id_receipt
        JOIN category c ON ri.id_category = c.id_category
        WHERE r.id_user = ?
          AND YEAR(r.created_at) = ?
        GROUP BY c.id_category, c.name_category
        ORDER BY total DESC
    ');
    $stmt->bind_param('ii', $user['id_user'], $year);
}

$stmt->execute();
$per_category = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);

// 4. Spending per minggu untuk bulan terpilih
$per_week = [];

if ($month !== null) {
    $stmt = $db->prepare('
        SELECT 
            CEIL(DAY(r.created_at) / 7) AS week_num,
            SUM(ri.price * ri.quantity) AS total
        FROM receipt r
        JOIN receipt_item ri ON r.id_receipt = ri.id_receipt
        WHERE r.id_user = ?
          AND YEAR(r.created_at) = ?
          AND MONTH(r.created_at) = ?
        GROUP BY CEIL(DAY(r.created_at) / 7)
        ORDER BY week_num ASC
    ');
    $stmt->bind_param('iii', $user['id_user'], $year, $month);
    $stmt->execute();
    $rows = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);

    foreach ($rows as $row) {
        $per_week[] = [
            'week' => 'Week ' . $row['week_num'],
            'total' => $row['total']
        ];
    }
}

// 5. Rekomendasi budget
$stmt = $db->prepare('
    SELECT AVG(monthly_total) AS avg_total FROM (
        SELECT SUM(ri.price * ri.quantity) AS monthly_total
        FROM receipt r
        JOIN receipt_item ri ON r.id_receipt = ri.id_receipt
        WHERE r.id_user = ?
          AND (
              YEAR(r.created_at) < ?
              OR (YEAR(r.created_at) = ? AND MONTH(r.created_at) < MONTH(NOW()))
          )
        GROUP BY YEAR(r.created_at), MONTH(r.created_at)
    ) AS t
');
$stmt->bind_param('iii', $user['id_user'], $year, $year);
$stmt->execute();
$avg = $stmt->get_result()->fetch_assoc()['avg_total'] ?? 0;

$recommendation = $avg ? round($avg * 0.92) : null;

$db->close();

success([
    'monthly'        => $monthly,
    'month_total'    => $monthTotal,
    'per_category'   => $per_category,
    'per_week'       => $per_week,
    'recommendation' => $recommendation,
]);