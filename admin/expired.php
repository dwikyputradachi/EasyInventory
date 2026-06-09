<?php
require_once 'auth.php';
include 'koneksi.php';

if (
    isset($_POST['delete_all_expired']) &&
    $_POST['delete_all_expired'] == '1'
) {
    $connect->query("
        DELETE FROM item
        WHERE expired_date IS NOT NULL
        AND expired_date < CURDATE()
    ");

    header("Location: expired.php?tab=expired");
    exit;
}

$page_title  = 'Expired Items Monitor';
$active_menu = 'expired';

$tab = isset($_GET['tab']) ? $_GET['tab'] : 'soon';

$expired_items = [];
$r = $connect->query("
    SELECT i.*, c.name_category, u.name AS user_name
    FROM item i
    LEFT JOIN category c ON i.id_category = c.id_category
    LEFT JOIN users u ON i.id_user = u.id_user
    WHERE i.expired_date IS NOT NULL
    AND i.expired_date < CURDATE()
    ORDER BY i.expired_date ASC
");
if ($r) while ($row = $r->fetch_assoc()) $expired_items[] = $row;

$soon_items = [];
$r = $connect->query("
    SELECT i.*, c.name_category, u.name AS user_name,
    DATEDIFF(i.expired_date, CURDATE()) AS days_left
    FROM item i
    LEFT JOIN category c ON i.id_category = c.id_category
    LEFT JOIN users u ON i.id_user = u.id_user
    WHERE i.expired_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)
    ORDER BY i.expired_date ASC
");
if ($r) while ($row = $r->fetch_assoc()) $soon_items[] = $row;

$month_items = [];
$r = $connect->query("
    SELECT i.*, c.name_category, u.name AS user_name,
    DATEDIFF(i.expired_date, CURDATE()) AS days_left
    FROM item i
    LEFT JOIN category c ON i.id_category = c.id_category
    LEFT JOIN users u ON i.id_user = u.id_user
    WHERE i.expired_date BETWEEN DATE_ADD(CURDATE(), INTERVAL 8 DAY)
    AND DATE_ADD(CURDATE(), INTERVAL 30 DAY)
    ORDER BY i.expired_date ASC
");
if ($r) while ($row = $r->fetch_assoc()) $month_items[] = $row;

$list = $tab === 'expired'
    ? $expired_items
    : ($tab === 'soon' ? $soon_items : $month_items);

ob_start();
?>

<div class="row g-3 mb-4">
    <div class="col-md-4">
        <a href="?tab=expired" style="text-decoration:none;color:inherit;">
            <div class="stat-card" style="border-color:<?= $tab === 'expired' ? '#ef4444' : 'var(--border)' ?>;">
                <div>
                    <div class="stat-label">Already Expired</div>
                    <div class="stat-value" style="color:#ef4444;"><?= count($expired_items) ?></div>
                    <div class="stat-sub">items</div>
                </div>
                <div class="stat-icon" style="background:#fee2e2;color:#ef4444;">
                    <i class="bi bi-x-circle-fill"></i>
                </div>
            </div>
        </a>
    </div>

    <div class="col-md-4">
        <a href="?tab=soon" style="text-decoration:none;color:inherit;">
            <div class="stat-card" style="border-color:<?= $tab === 'soon' ? '#f59e0b' : 'var(--border)' ?>;">
                <div>
                    <div class="stat-label">Expiring Soon</div>
                    <div class="stat-value" style="color:#f59e0b;"><?= count($soon_items) ?></div>
                    <div class="stat-sub">within 7 days</div>
                </div>
                <div class="stat-icon" style="background:#fef3c7;color:#f59e0b;">
                    <i class="bi bi-clock-history"></i>
                </div>
            </div>
        </a>
    </div>

    <div class="col-md-4">
        <a href="?tab=month" style="text-decoration:none;color:inherit;">
            <div class="stat-card" style="border-color:<?= $tab === 'month' ? '#3b82f6' : 'var(--border)' ?>;">
                <div>
                    <div class="stat-label">Within 30 Days</div>
                    <div class="stat-value" style="color:#3b82f6;"><?= count($month_items) ?></div>
                    <div class="stat-sub">items</div>
                </div>
                <div class="stat-icon" style="background:#dbeafe;color:#3b82f6;">
                    <i class="bi bi-calendar-event-fill"></i>
                </div>
            </div>
        </a>
    </div>
</div>

<div class="table-wrap">
    <div class="card-header-custom">
        <span class="ch-title">
            <?php if ($tab === 'expired'): ?>
                Already Expired Items (<?= count($expired_items) ?>)
            <?php elseif ($tab === 'soon'): ?>
                Expiring Soon — 7 Days (<?= count($soon_items) ?>)
            <?php else: ?>
                Expiring within 30 Days (<?= count($month_items) ?>)
            <?php endif; ?>
        </span>

        <div class="d-flex gap-2 align-items-center">
            <?php if ($tab === 'expired' && count($expired_items) > 0): ?>
                <form method="POST"
                      onsubmit="return confirm('Delete all expired items? This action cannot be undone.');">
                    <input type="hidden" name="delete_all_expired" value="1">
                    <button type="submit" class="btn btn-danger btn-sm">
                        Delete All Expired
                    </button>
                </form>
            <?php endif; ?>

            <div class="d-flex gap-1">
                <a href="?tab=expired" class="btn btn-sm <?= $tab === 'expired' ? 'btn-primary' : 'btn-outline-secondary' ?>">
                    Expired
                </a>
                <a href="?tab=soon" class="btn btn-sm <?= $tab === 'soon' ? 'btn-primary' : 'btn-outline-secondary' ?>">
                    7 Days
                </a>
                <a href="?tab=month" class="btn btn-sm <?= $tab === 'month' ? 'btn-primary' : 'btn-outline-secondary' ?>">
                    30 Days
                </a>
            </div>
        </div>
    </div>

    <div style="overflow-x:auto;">
        <table class="table">
            <thead>
                <tr>
                    <th>#</th>
                    <th>Item Name</th>
                    <th>Category</th>
                    <th>Qty</th>
                    <th>Expiry Date</th>
                    <?php if ($tab !== 'expired'): ?>
                        <th>Days Left</th>
                    <?php endif; ?>
                    <th>User</th>
                </tr>
            </thead>

            <tbody>
                <?php if (empty($list)): ?>
                    <tr>
                        <td colspan="<?= $tab !== 'expired' ? 7 : 6 ?>" class="text-center py-4 text-muted">
                            No items in this category
                        </td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($list as $i => $item): ?>
                        <tr>
                            <td><?= $i + 1 ?></td>
                            <td><strong><?= htmlspecialchars($item['name']) ?></strong></td>
                            <td><?= htmlspecialchars($item['name_category'] ?? '-') ?></td>
                            <td>
                                <?= (int)($item['quantity'] ?? 0) ?>
                                <?= htmlspecialchars($item['unit'] ?? '') ?>
                            </td>
                            <td><?= date('d M Y', strtotime($item['expired_date'])) ?></td>

                            <?php if ($tab !== 'expired'): ?>
                                <td><?= (int)$item['days_left'] ?> days</td>
                            <?php endif; ?>

                            <td><?= htmlspecialchars($item['user_name'] ?? '-') ?></td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<?php
$content = ob_get_clean();
include 'layout.php';
?>
