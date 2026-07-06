<?php
require_once 'auth.php';
include 'koneksi.php';
$page_title  = 'Inventory Monitor';
$active_menu = 'inventaris';

// FILTER
$fuser = isset($_GET['user']) ? (int)$_GET['user'] : 0;
$fcat  = isset($_GET['cat'])  ? (int)$_GET['cat']  : 0;
$search= isset($_GET['q'])    ? $connect->real_escape_string(trim($_GET['q'])) : '';

$where_parts = [];
if($fuser)  $where_parts[] = "i.id_user=$fuser";
if($fcat)   $where_parts[] = "i.id_category=$fcat";
if($search) $where_parts[] = "(i.name LIKE '%$search%' OR i.barcode LIKE '%$search%')";
$where = $where_parts ? 'WHERE '.implode(' AND ',$where_parts) : '';

$items = [];
$r = $connect->query("SELECT i.*, c.name_category, u.name as user_name, u.email as user_email
                       FROM item i
                       LEFT JOIN category c ON i.id_category=c.id_category
                       LEFT JOIN users u ON i.id_user=u.id_user
                       $where
                       ORDER BY u.name, i.name");
if($r) while($row=$r->fetch_assoc()) $items[] = $row;

// Dropdown users & categories
$users = [];
$r = $connect->query("SELECT id_user,name FROM users ORDER BY name");
if($r) while($row=$r->fetch_assoc()) $users[]=$row;

$kategori = [];
$r = $connect->query("SELECT id_category,name_category FROM category ORDER BY name_category");
if($r) while($row=$r->fetch_assoc()) $kategori[]=$row;

// Summary per user (no filter)
$user_summary = [];
$r = $connect->query("
SELECT u.name, u.email, COUNT(i.id_item) as total_item,
       SUM(CASE WHEN i.expired_date < CURDATE() THEN 1 ELSE 0 END) as expired,
       SUM(CASE WHEN i.quantity <= 0 THEN 1 ELSE 0 END) as habis
FROM users u 
LEFT JOIN item i ON u.id_user = i.id_user
GROUP BY u.id_user 
ORDER BY total_item DESC 
LIMIT 6
");
if($r) while($row=$r->fetch_assoc()) $user_summary[]=$row;

ob_start();
?>

<!-- Filter -->
<form method="GET" class="d-flex flex-wrap gap-2 mb-3 align-items-center">
    <div class="search-box">
        <i class="bi bi-search"></i>
        <input type="text" name="q" class="form-control" placeholder="Search item..." value="<?= htmlspecialchars($search) ?>" style="width:200px;">
    </div>
    <select name="user" class="form-select" style="width:170px;">
        <option value="">All Users</option>
        <?php foreach($users as $u): ?>
        <option value="<?= $u['id_user'] ?>" <?= $fuser==$u['id_user']?'selected':'' ?>><?= htmlspecialchars($u['name']) ?></option>
        <?php endforeach; ?>
    </select>
    <select name="cat" class="form-select" style="width:160px;">
        <option value="">All Categories</option>
        <?php foreach($kategori as $k): ?>
        <option value="<?= $k['id_category'] ?>" <?= $fcat==$k['id_category']?'selected':'' ?>><?= htmlspecialchars($k['name_category']) ?></option>
        <?php endforeach; ?>
    </select>
    <button class="btn btn-primary"><i class="bi bi-funnel me-1"></i>Filter</button>
    <a href="inventaris.php" class="btn btn-outline-secondary">Reset</a>
    <span class="text-muted ms-auto" style="font-size:13px;"><?= count($items) ?> items found</span>
</form>

<!-- Table -->
<div class="table-wrap">
    <div class="card-header-custom">
        <span class="ch-title"><i class="bi bi-clipboard2-data-fill me-2 text-primary"></i>All Users Inventory</span>
    </div>
    <div style="overflow-x:auto;">
    <table class="table">
        <thead>
            <tr>
                <th>#</th>
                <th>Item Name</th>
                <th>Category</th>
                <th>Qty / Stock</th>
                <th>Unit</th>
                <th>Price</th>
                <th>Barcode</th>
                <th>Expiry</th>
                <th>User</th>
                <th>Status</th>
            </tr>
        </thead>
       <tbody>
    <?php if(empty($items)): ?>
        <tr>
            <td colspan="10" class="text-center text-muted py-4">
                No inventory data found
            </td>
        </tr>
    <?php else: foreach($items as $i => $item):
        $exp = $item['expired_date'] ?? null;
        $label = 'Good';

        if (($item['quantity'] ?? 1) <= 0) {
            $label = 'Out of Stock';
        } elseif ($exp) {
            $diff = (strtotime($exp) - time()) / 86400;

            if ($diff < 0) {
                $label = 'Expired';
            } elseif ($diff <= 7) {
                $label = 'Expiring Soon';
            } elseif ($diff <= 30) {
                $label = '1 Month Left';
            }
        }
    ?>
        <tr>
            <td><?= $i + 1 ?></td>

            <td>
                <strong><?= htmlspecialchars($item['name']) ?></strong>
            </td>

            <td>
                <?= htmlspecialchars($item['name_category'] ?? '-') ?>
            </td>

            <td>
                <?= ($item['quantity'] ?? 0) ?> / <?= ($item['stok'] ?? 0) ?>
            </td>

            <td>
                <?= htmlspecialchars($item['unit'] ?? '-') ?>
            </td>

            <td>
                Rp<?= number_format($item['price'] ?? 0, 0, ',', '.') ?>
            </td>

            <td>
                <?= !empty($item['barcode'])
                    ? htmlspecialchars($item['barcode'])
                    : '<span class="text-muted">-</span>' ?>
            </td>

            <td>
                <?= $exp
                    ? date('d M Y', strtotime($exp))
                    : '<span class="text-muted">-</span>' ?>
            </td>

            <td>
                <div><?= htmlspecialchars($item['user_name'] ?? '-') ?></div>
                <div style="font-size:11px;color:var(--muted);">
                    <?= htmlspecialchars($item['user_email'] ?? '') ?>
                </div>
            </td>

            <td>
                <?= $label ?>
            </td>
        </tr>
    <?php endforeach; endif; ?>
</tbody>
    </table>
    </div>
</div>

<?php
$content = ob_get_clean();
include 'layout.php';
?>
