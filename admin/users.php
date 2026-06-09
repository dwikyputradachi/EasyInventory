<?php
require_once 'auth.php';
include 'koneksi.php';

$page_title  = 'Manage Users';
$active_menu = 'users';

$msg = '';

// UPDATE ROLE
if (isset($_POST['update_role'])) {
    $id   = (int)$_POST['id_user'];
    $role = $_POST['role'] === 'admin' ? 'admin' : 'user';

    $connect->query("UPDATE users SET role='$role' WHERE id_user=$id");
    $msg = '<div class="alert alert-success">User role updated successfully.</div>';
}

// DELETE
if (isset($_POST['delete_user'])) {
    $id = (int)$_POST['id_user'];
    $connect->query("DELETE FROM users WHERE id_user=$id");
    $msg = '<div class="alert alert-success">User deleted successfully.</div>';
}

// SEARCH + FETCH
$search = isset($_GET['q']) ? $connect->real_escape_string(trim($_GET['q'])) : '';
$where  = $search ? "WHERE name LIKE '%$search%' OR email LIKE '%$search%'" : '';

$users = [];
$r = $connect->query("SELECT * FROM users $where ORDER BY id_user DESC");
if ($r) while ($row = $r->fetch_assoc()) $users[] = $row;

ob_start();
?>

<?= $msg ?>

<div class="table-wrap">
    <div class="card-header-custom">
      <span class="ch-title">
    User List (<?= count($users) ?>)
</span>

        <form method="GET" class="d-flex gap-2">
            <div class="search-box">
                <i class="bi bi-search"></i>
                <input type="text" name="q" class="form-control form-control-sm"
                       placeholder="Search name / email..."
                       value="<?= htmlspecialchars($search) ?>" style="width:220px;">
            </div>
            <button class="btn btn-sm btn-primary">Search</button>
            <?php if($search): ?>
                <a href="users.php" class="btn btn-sm btn-outline-secondary">Reset</a>
            <?php endif; ?>
        </form>
    </div>

    <table class="table">
        <thead>
            <tr>
                <th>#</th>
                <th>Name</th>
                <th>Email</th>
                <th>Role</th>
                <th style="width:180px;">Action</th>
            </tr>
        </thead>

        <tbody>
            <?php if(empty($users)): ?>
                <tr>
                    <td colspan="5" class="text-center text-muted py-4">No users found</td>
                </tr>
            <?php else: foreach($users as $i => $u): ?>
                <tr>
                    <td><?= $i + 1 ?></td>

                    <td>
                        <strong><?= htmlspecialchars($u['name']) ?></strong>
                    </td>

                    <td><?= htmlspecialchars($u['email']) ?></td>

<td><?= htmlspecialchars($u['role']) ?></td>

                   <td>
    <form method="POST">
        <input type="hidden" name="id_user" value="<?= $u['id_user'] ?>">

        <select name="role" class="form-select form-select-sm" onchange="this.form.submit()">
            <option value="user" <?= $u['role'] === 'user' ? 'selected' : '' ?>>User</option>
            <option value="admin" <?= $u['role'] === 'admin' ? 'selected' : '' ?>>Admin</option>
        </select>

        <input type="hidden" name="update_role" value="1">
    </form>
</td>
                </tr>
            <?php endforeach; endif; ?>
        </tbody>
    </table>
</div>

<?php
$content = ob_get_clean();
include 'layout.php';
?>