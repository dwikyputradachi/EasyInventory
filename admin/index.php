<?php
require_once 'auth.php';
include 'koneksi.php';

$page_title  = 'Dashboard';
$active_menu = 'dashboard';

ini_set('display_errors', 1);
error_reporting(E_ALL);

function qCount($db, $sql) {
    $r = $db->query($sql);
    return $r ? (int)$r->fetch_assoc()['c'] : 0;
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

$stats = [
    'total_users'    => qCount($connect, "SELECT COUNT(*) c FROM users"),
    'total_items'    => qCount($connect, "SELECT COUNT(*) c FROM item"),
    'total_kategori' => qCount($connect, "SELECT COUNT(*) c FROM category"),
];

$recent_items = qRows($connect, "
    SELECT 
        i.id_item,
        i.name,
        i.stok,
        i.quantity,
        i.unit,
        i.expired_date,
        c.name_category,
        u.name AS user_name
    FROM item i
    LEFT JOIN category c ON i.id_category = c.id_category
    LEFT JOIN users u ON i.id_user = u.id_user
    ORDER BY i.id_item DESC
    LIMIT 8
");

$kategori_stok = qRows($connect, "
    SELECT c.name_category, COUNT(i.id_item) AS total
    FROM category c
    LEFT JOIN item i ON c.id_category = i.id_category
    GROUP BY c.id_category, c.name_category
    ORDER BY total DESC
    LIMIT 6
");

$recent_users = qRows($connect, "
    SELECT id_user, name, email, role
    FROM users
    ORDER BY id_user DESC
    LIMIT 5
");

$cards = [
    [
        'label' => 'Total Users',
        'sub'   => 'registered users',
        'val'   => $stats['total_users'],
        'color' => '#16a34a',
        'bg'    => '#dcfce7',
        'icon'  => 'people-fill',
    ],
    [
        'label' => 'Total Items',
        'sub'   => 'inventory items',
        'val'   => $stats['total_items'],
        'color' => '#0f8b7b',
        'bg'    => '#ccfbf1',
        'icon'  => 'basket3-fill',
    ],
    [
        'label' => 'Categories',
        'sub'   => 'item categories',
        'val'   => $stats['total_kategori'],
        'color' => '#8b5cf6',
        'bg'    => '#ede9fe',
        'icon'  => 'tags-fill',
    ],
];

ob_start();
?>

<div class="row g-3 mb-4">
    <?php foreach ($cards as $c): ?>
        <div class="col-12 col-md-4">
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

<div class="row g-3">
    <div class="col-lg-8">
        <div class="table-wrap">
            <div class="card-header-custom">
                <span class="ch-title">
                    <i class="bi bi-clock-history me-2 text-primary"></i>
                    Recent Items
                </span>
                <a href="barang.php" class="btn btn-sm btn-outline-secondary">View All</a>
            </div>

            <div class="table-responsive">
                <table class="table align-middle mb-0">
                    <thead>
                        <tr>
                            <th>Item Name</th>
                            <th>Category</th>
                            <th>Stock</th>
                            <th>Expiry Date</th>
                            <th>User</th>
                        </tr>
                    </thead>

                    <tbody>
                        <?php if (empty($recent_items)): ?>
                            <tr>
                                <td colspan="5" class="text-center text-muted py-4">
                                    No items yet
                                </td>
                            </tr>
                        <?php else: ?>
                            <?php foreach ($recent_items as $item): ?>
                                <?php
                                    $stock = $item['stok'] ?? $item['quantity'] ?? 0;
                                    $unit  = $item['unit'] ?? '';
                                    $exp   = $item['expired_date'] ?? null;
                                ?>

                                <tr>
                                    <td>
                                        <strong><?= htmlspecialchars($item['name'] ?? '-') ?></strong>
                                    </td>

                                    <td>
                                        <span class="badge rounded-pill bg-light text-dark border">
                                            <?= htmlspecialchars($item['name_category'] ?? '-') ?>
                                        </span>
                                    </td>

                                    <td>
                                        <?= (int)$stock ?> <?= htmlspecialchars($unit) ?>
                                    </td>

                                    <td>
                                        <?php if (!empty($exp)): ?>
                                            <?= date('d M Y', strtotime($exp)) ?>
                                        <?php else: ?>
                                            <span class="text-muted">-</span>
                                        <?php endif; ?>
                                    </td>

                                    <td>
                                        <?= htmlspecialchars($item['user_name'] ?? '-') ?>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                        <?php endif; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <div class="col-lg-4">
        <div class="table-wrap mb-3">
            <div class="card-header-custom">
                <span class="ch-title">
                    <i class="bi bi-bar-chart-fill me-2" style="color:#8b5cf6;"></i>
                    Items per Category
                </span>
            </div>

            <div style="padding:16px;">
                <?php
                    $colors = ['#0f8b7b', '#22c55e', '#f59e0b', '#38bdf8', '#8b5cf6', '#64748b'];
                    $totals = array_column($kategori_stok, 'total');
                    $max = !empty($totals) ? max($totals) : 1;
                ?>

                <?php if (empty($kategori_stok)): ?>
                    <p class="text-muted text-center" style="font-size:13px;">
                        No data yet
                    </p>
                <?php else: ?>
                    <?php foreach ($kategori_stok as $i => $ks): ?>
                        <?php $pct = $max > 0 ? round($ks['total'] / $max * 100) : 0; ?>

                        <div style="margin-bottom:14px;">
                            <div style="display:flex;justify-content:space-between;font-size:12.5px;font-weight:600;margin-bottom:5px;">
                                <span><?= htmlspecialchars($ks['name_category'] ?? '-') ?></span>
                                <span style="color:var(--muted);">
                                    <?= (int)$ks['total'] ?> items
                                </span>
                            </div>

                            <div style="background:#f1f5f9;border-radius:8px;height:8px;overflow:hidden;">
                                <?php 
$barColor = $colors[$i % count($colors)];
$pctSafe = max(0, min(100, (int)$pct));
?>

<div style="width:<?= $pctSafe ?>%; height:100%; background:<?= $barColor ?>; border-radius:8px;"></div>
                            </div>
                        </div>
                    <?php endforeach; ?>
                <?php endif; ?>
            </div>
        </div>

        <div class="table-wrap">
            <div class="card-header-custom">
                <span class="ch-title">
                    <i class="bi bi-person-lines-fill me-2 text-primary"></i>
                    Recent Users
                </span>
                <a href="users.php" class="btn btn-sm btn-outline-secondary">All</a>
            </div>

            <div style="padding:8px 0;">
                <?php if (empty($recent_users)): ?>
                    <p class="text-center text-muted py-3" style="font-size:13px;">
                        No users yet
                    </p>
                <?php else: ?>
                    <?php foreach ($recent_users as $u): ?>
                        <div style="
                            display:flex;
                            align-items:center;
                            gap:10px;
                            padding:10px 16px;
                            border-bottom:1px solid #f1f5f9;
                        ">
                            <div style="
                                width:34px;
                                height:34px;
                                background:var(--primary-light);
                                border-radius:50%;
                                display:flex;
                                align-items:center;
                                justify-content:center;
                                font-weight:700;
                                font-size:13px;
                                color:var(--primary);
                                flex-shrink:0;
                            ">
                                <?= strtoupper(substr($u['name'] ?? 'U', 0, 1)) ?>
                            </div>

                            <div style="flex:1;min-width:0;">
                                <div style="
                                    font-size:13px;
                                    font-weight:600;
                                    white-space:nowrap;
                                    overflow:hidden;
                                    text-overflow:ellipsis;
                                ">
                                    <?= htmlspecialchars($u['name'] ?? '-') ?>
                                </div>

                                <div style="
                                    font-size:11.5px;
                                    color:var(--muted);
                                    white-space:nowrap;
                                    overflow:hidden;
                                    text-overflow:ellipsis;
                                ">
                                    <?= htmlspecialchars($u['email'] ?? '-') ?>
                                </div>
                            </div>

                            <span class="badge bg-light text-dark border">
                                <?= htmlspecialchars($u['role'] ?? 'user') ?>
                            </span>
                        </div>
                    <?php endforeach; ?>
                <?php endif; ?>
            </div>
        </div>
    </div>
</div>

<?php
$content = ob_get_clean();
include 'layout.php';
?>
