<?php
require_once 'auth.php';
include 'koneksi.php';

$page_title  = 'Receipt Activity';
$active_menu = 'spending';

ini_set('display_errors', 1);
error_reporting(E_ALL);

function qValue($db, $sql) {
    $r = $db->query($sql);
    if (!$r) return 0;

    $row = $r->fetch_assoc();
    return $row ? ($row['c'] ?? 0) : 0;
}

function qRows($db, $sql) {
    $r = $db->query($sql);
    $rows = [];

    if ($r) {
        while ($row = $r->fetch_assoc()) {
            $rows[] = $row;
        }
    }

    return $rows;
}

// ===============================
// FILTER
// ===============================

$year  = isset($_GET['year']) ? (int)$_GET['year'] : (int)date('Y');
$month = isset($_GET['month']) ? (int)$_GET['month'] : 0;
$fcat  = isset($_GET['cat']) ? (int)$_GET['cat'] : 0;

$where = [];
$where[] = "YEAR(r.created_at) = $year";

if ($month >= 1 && $month <= 12) {
    $where[] = "MONTH(r.created_at) = $month";
}

if ($fcat > 0) {
    $where[] = "ri.id_category = $fcat";
}

$whereSql = "WHERE " . implode(" AND ", $where);

// ===============================
// DROPDOWN DATA
// ===============================

$categories = qRows($connect, "
    SELECT id_category, name_category
    FROM category
    ORDER BY name_category
");

// ===============================
// SUMMARY STATS
// Tanpa nominal spending dan tanpa nama user
// ===============================

$total_receipts = qValue($connect, "
    SELECT COUNT(DISTINCT r.id_receipt) c
    FROM receipt r
    JOIN receipt_item ri ON r.id_receipt = ri.id_receipt
    $whereSql
");

$total_items_recorded = qValue($connect, "
    SELECT COALESCE(SUM(ri.quantity), 0) c
    FROM receipt r
    JOIN receipt_item ri ON r.id_receipt = ri.id_receipt
    $whereSql
");

$ocr_receipts = qValue($connect, "
    SELECT COUNT(DISTINCT r.id_receipt) c
    FROM receipt r
    JOIN receipt_item ri ON r.id_receipt = ri.id_receipt
    $whereSql
    AND r.name LIKE '%OCR%'
");

$manual_receipts = qValue($connect, "
    SELECT COUNT(DISTINCT r.id_receipt) c
    FROM receipt r
    JOIN receipt_item ri ON r.id_receipt = ri.id_receipt
    $whereSql
    AND (
        r.name LIKE '%Manual%'
        OR r.name LIKE '%Barcode%'
        OR r.name LIKE '%Add Product%'
    )
");

$restock_receipts = qValue($connect, "
    SELECT COUNT(DISTINCT r.id_receipt) c
    FROM receipt r
    JOIN receipt_item ri ON r.id_receipt = ri.id_receipt
    $whereSql
    AND r.name LIKE '%Restock%'
");

// ===============================
// ACTIVITY DATA
// ===============================

$activity_per_category = qRows($connect, "
    SELECT 
        COALESCE(c.name_category, 'Uncategorized') AS name_category,
        COUNT(ri.id_receipt_item) AS total_records,
        COALESCE(SUM(ri.quantity), 0) AS total_quantity
    FROM receipt r
    JOIN receipt_item ri ON r.id_receipt = ri.id_receipt
    LEFT JOIN category c ON ri.id_category = c.id_category
    $whereSql
    GROUP BY c.id_category, c.name_category
    ORDER BY total_records DESC
");

$activity_per_month = qRows($connect, "
    SELECT 
        MONTH(r.created_at) AS month_num,
        DATE_FORMAT(r.created_at, '%M %Y') AS month_name,
        COUNT(DISTINCT r.id_receipt) AS total_receipts,
        COUNT(ri.id_receipt_item) AS total_records,
        COALESCE(SUM(ri.quantity), 0) AS total_quantity
    FROM receipt r
    JOIN receipt_item ri ON r.id_receipt = ri.id_receipt
    WHERE YEAR(r.created_at) = $year
    " . ($fcat > 0 ? " AND ri.id_category = $fcat" : "") . "
    GROUP BY MONTH(r.created_at), DATE_FORMAT(r.created_at, '%M %Y')
    ORDER BY month_num ASC
");

$recent_activity = qRows($connect, "
    SELECT 
        r.id_receipt,
        r.name AS receipt_name,
        r.created_at,
        COUNT(ri.id_receipt_item) AS total_records,
        COALESCE(SUM(ri.quantity), 0) AS total_quantity
    FROM receipt r
    JOIN receipt_item ri ON r.id_receipt = ri.id_receipt
    $whereSql
    GROUP BY r.id_receipt, r.name, r.created_at
    ORDER BY r.created_at DESC
    LIMIT 12
");

$cards = [
    [
        'label' => 'Total Receipts',
        'sub'   => 'selected period',
        'val'   => (int)$total_receipts,
        'color' => '#0ea5e9',
        'bg'    => '#e0f2fe',
        'icon'  => 'receipt-cutoff',
    ],
    [
        'label' => 'OCR Receipts',
        'sub'   => 'receipt scan activity',
        'val'   => (int)$ocr_receipts,
        'color' => '#8b5cf6',
        'bg'    => '#ede9fe',
        'icon'  => 'file-earmark-text',
    ],
    [
        'label' => 'Manual Purchase',
        'sub'   => 'manual/barcode activity',
        'val'   => (int)$manual_receipts,
        'color' => '#16a34a',
        'bg'    => '#dcfce7',
        'icon'  => 'plus-circle',
    ],
    [
        'label' => 'Restock Activity',
        'sub'   => 'stock-in records',
        'val'   => (int)$restock_receipts,
        'color' => '#f59e0b',
        'bg'    => '#fef3c7',
        'icon'  => 'box-seam',
    ],
    [
        'label' => 'Items Recorded',
        'sub'   => 'total quantity',
        'val'   => (int)$total_items_recorded,
        'color' => '#0f8b7b',
        'bg'    => '#ccfbf1',
        'icon'  => 'basket3-fill',
    ],
];

ob_start();
?>

<!-- FILTER -->
<form method="GET" class="d-flex flex-wrap gap-2 mb-3 align-items-center">
    <select name="year" class="form-select" style="width:120px;">
        <?php for ($y = date('Y'); $y >= date('Y') - 5; $y--): ?>
            <option value="<?= $y ?>" <?= $year == $y ? 'selected' : '' ?>>
                <?= $y ?>
            </option>
        <?php endfor; ?>
    </select>

    <select name="month" class="form-select" style="width:160px;">
        <option value="0">All Months</option>
        <?php
        $monthNames = [
            1 => 'January', 2 => 'February', 3 => 'March', 4 => 'April',
            5 => 'May', 6 => 'June', 7 => 'July', 8 => 'August',
            9 => 'September', 10 => 'October', 11 => 'November', 12 => 'December'
        ];
        ?>
        <?php foreach ($monthNames as $num => $name): ?>
            <option value="<?= $num ?>" <?= $month == $num ? 'selected' : '' ?>>
                <?= $name ?>
            </option>
        <?php endforeach; ?>
    </select>

    <select name="cat" class="form-select" style="width:190px;">
        <option value="0">All Categories</option>
        <?php foreach ($categories as $c): ?>
            <option value="<?= $c['id_category'] ?>" <?= $fcat == $c['id_category'] ? 'selected' : '' ?>>
                <?= htmlspecialchars($c['name_category']) ?>
            </option>
        <?php endforeach; ?>
    </select>

    <button class="btn btn-primary">
        <i class="bi bi-funnel me-1"></i>Filter
    </button>

    <a href="spending.php" class="btn btn-outline-secondary">
        Reset
    </a>
</form>

<!-- PRIVACY NOTE -->
<div class="alert alert-light border mb-3" style="font-size:13px;">
    <i class="bi bi-shield-lock-fill me-1 text-primary"></i>
    This page only shows aggregated receipt activity. User spending details and personal purchase history are not displayed.
</div>

<!-- CARDS -->
<div class="row g-3 mb-4">
    <?php foreach ($cards as $c): ?>
        <div class="col-12 col-md-6 col-lg-4">
            <div class="stat-card">
                <div>
                    <div class="stat-label"><?= htmlspecialchars($c['label']) ?></div>
                    <div class="stat-value" style="color:<?= $c['color'] ?>;">
                        <?= $c['val'] ?>
                    </div>
                    <div class="stat-sub"><?= htmlspecialchars($c['sub']) ?></div>
                </div>

                <div class="stat-icon" style="background:<?= $c['bg'] ?>;color:<?= $c['color'] ?>;">
                    <i class="bi bi-<?= $c['icon'] ?>"></i>
                </div>
            </div>
        </div>
    <?php endforeach; ?>
</div>

<div class="row g-3 mb-4">
    <!-- ACTIVITY PER CATEGORY -->
    <div class="col-lg-6">
        <div class="table-wrap">
            <div class="card-header-custom">
                <span class="ch-title">
                    <i class="bi bi-pie-chart-fill me-2 text-warning"></i>
                    Activity per Category
                </span>
            </div>

            <div style="padding:16px;">
                <?php
                $colors = ['#0f8b7b', '#22c55e', '#f59e0b', '#38bdf8', '#8b5cf6', '#64748b'];
                $catTotals = array_column($activity_per_category, 'total_records');
                $catMax = !empty($catTotals) ? max($catTotals) : 1;
                ?>

                <?php if (empty($activity_per_category)): ?>
                    <p class="text-center text-muted mb-0" style="font-size:13px;">
                        No category activity data
                    </p>
                <?php else: ?>
                    <?php foreach ($activity_per_category as $i => $cat): ?>
                        <?php
                        $pct = $catMax > 0 ? round(($cat['total_records'] / $catMax) * 100) : 0;
                        $pctSafe = max(0, min(100, (int)$pct));
                        $barColor = $colors[$i % count($colors)];
                        ?>

                        <div style="margin-bottom:14px;">
                            <div style="display:flex;justify-content:space-between;font-size:12.5px;font-weight:600;margin-bottom:5px;">
                                <span><?= htmlspecialchars($cat['name_category'] ?? '-') ?></span>
                                <span style="color:var(--muted);">
                                    <?= (int)($cat['total_records'] ?? 0) ?> records
                                </span>
                            </div>

                            <div style="font-size:11.5px;color:var(--muted);margin-bottom:5px;">
                                Quantity: <?= (int)($cat['total_quantity'] ?? 0) ?>
                            </div>

                            <div style="background:#f1f5f9;border-radius:8px;height:8px;overflow:hidden;">
                                <div style="width:<?= $pctSafe ?>%; height:100%; background:<?= $barColor ?>; border-radius:8px;"></div>
                            </div>
                        </div>
                    <?php endforeach; ?>
                <?php endif; ?>
            </div>
        </div>
    </div>

    <!-- ACTIVITY PER MONTH -->
    <div class="col-lg-6">
        <div class="table-wrap">
            <div class="card-header-custom">
                <span class="ch-title">
                    <i class="bi bi-calendar3 me-2 text-primary"></i>
                    Activity per Month
                </span>
            </div>

            <div class="table-responsive">
                <table class="table align-middle mb-0">
                    <thead>
                        <tr>
                            <th>Month</th>
                            <th>Receipts</th>
                            <th>Records</th>
                            <th>Qty</th>
                        </tr>
                    </thead>

                    <tbody>
                        <?php if (empty($activity_per_month)): ?>
                            <tr>
                                <td colspan="4" class="text-center text-muted py-4">
                                    No monthly activity data
                                </td>
                            </tr>
                        <?php else: ?>
                            <?php foreach ($activity_per_month as $m): ?>
                                <tr>
                                    <td>
                                        <strong><?= htmlspecialchars($m['month_name'] ?? '-') ?></strong>
                                    </td>
                                    <td><?= (int)$m['total_receipts'] ?></td>
                                    <td><?= (int)$m['total_records'] ?></td>
                                    <td><?= (int)$m['total_quantity'] ?></td>
                                </tr>
                            <?php endforeach; ?>
                        <?php endif; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<!-- RECENT ACTIVITY -->
<div class="row g-3">
    <div class="col-12">
        <div class="table-wrap">
            <div class="card-header-custom">
                <span class="ch-title">
                    <i class="bi bi-clock-history me-2 text-primary"></i>
                    Recent Receipt Activity
                </span>
            </div>

            <div class="table-responsive">
                <table class="table align-middle mb-0">
                    <thead>
                        <tr>
                            <th>Activity Type</th>
                            <th>Date</th>
                            <th>Records</th>
                            <th>Quantity</th>
                        </tr>
                    </thead>

                    <tbody>
                        <?php if (empty($recent_activity)): ?>
                            <tr>
                                <td colspan="4" class="text-center text-muted py-4">
                                    No recent activity
                                </td>
                            </tr>
                        <?php else: ?>
                            <?php foreach ($recent_activity as $r): ?>
                                <tr>
                                    <td>
                                        <strong><?= htmlspecialchars($r['receipt_name'] ?? 'Receipt') ?></strong>
                                    </td>

                                    <td>
                                        <?= !empty($r['created_at'])
                                            ? date('d M Y H:i', strtotime($r['created_at']))
                                            : '<span class="text-muted">-</span>' ?>
                                    </td>

                                    <td><?= (int)$r['total_records'] ?></td>

                                    <td><?= (int)$r['total_quantity'] ?></td>
                                </tr>
                            <?php endforeach; ?>
                        <?php endif; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<?php
$content = ob_get_clean();
include 'layout.php';
?>