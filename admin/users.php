<?php
require_once 'auth.php';
include 'koneksi.php';
$page_title  = 'Manage Users';
$active_menu = 'users';

$msg = '';

// DELETE
if (isset($_POST['delete_user'])) {
    $id = (int)$_POST['id_user'];
    $connect->query("DELETE FROM users WHERE id_user=$id");
    $msg = '<div class="alert alert-success"><i class="bi bi-check-circle me-2"></i>User deleted successfully.</div>';
}

// SEARCH + FETCH
$search = isset($_GET['q']) ? $connect->real_escape_string(trim($_GET['q'])) : '';
$where  = $search ? "WHERE name LIKE '%$search%' OR email LIKE '%$search%'" : '';
$users  = [];
$r = $connect->query("SELECT * FROM users $where ORDER BY id_user DESC");
if ($r) while ($row = $r->fetch_assoc()) $users[] = $row;

ob_start();
?>

<?= $msg ?>

<div class="table-wrap">
    <div class="card-header-custom">
        <span class="ch-title"><i class="bi bi-people-fill me-2 text-primary"></i>User List (<?= count($users) ?>)</span>
        <form method="GET" class="d-flex gap-2">
            <div class="search-box">
                <i class="bi bi-search"></i>
                <input type="text" name="q" class="form-control form-control-sm" placeholder="Search name / email..." value="<?= htmlspecialchars($search) ?>" style="width:220px;">
            </div>
            <button class="btn btn-sm btn-primary">Search</button>
            <?php if($search): ?><a href="users.php" class="btn btn-sm btn-outline-secondary">Reset</a><?php endif; ?>
        </form>
    </div>
    <table class="table">
        <thead>
            <tr>
                <th>#</th>
                <th>Name</th>
                <th>Email</th>
            </tr>
        </thead>
        <tbody>
            <?php if(empty($users)): ?>
            <tr><td colspan="4" class="text-center text-muted py-4">No users found</td></tr>
            <?php else: foreach($users as $i => $u): ?>
            <tr>
                <td class="text-muted" style="font-family:'Space Mono',monospace;font-size:12px;"><?= $i+1 ?></td>
                <td>
                    <div style="display:flex;align-items:center;gap:9px;">
                        <div style="width:32px;height:32px;background:var(--primary-light);border-radius:50%;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:13px;color:var(--primary);flex-shrink:0;">
                            <?= strtoupper(substr($u['name'],0,1)) ?>
                        </div>
                        <strong><?= htmlspecialchars($u['name']) ?></strong>
                    </div>
                </td>
                <td><?= htmlspecialchars($u['email']) ?></td>
            </tr>
            <?php endforeach; endif; ?>
        </tbody>
    </table>
</div>

<?php
$content = ob_get_clean();
include 'layout.php';
?>
