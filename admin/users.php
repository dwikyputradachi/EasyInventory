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

// DELETE USER
if (isset($_POST['delete_user'])) {
    $id = (int)$_POST['id_user'];

    $connect->query("DELETE FROM users WHERE id_user=$id");
    $msg = '<div class="alert alert-warning">User deleted successfully.</div>';
}

// SEARCH + FETCH
$search = isset($_GET['q']) ? $connect->real_escape_string(trim($_GET['q'])) : '';
$where  = $search ? "WHERE name LIKE '%$search%' OR email LIKE '%$search%'" : '';

$users = [];
$r = $connect->query("SELECT * FROM users $where ORDER BY id_user DESC");
if ($r) {
    while ($row = $r->fetch_assoc()) {
        $users[] = $row;
    }
}

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
                <input 
                    type="text" 
                    name="q" 
                    class="form-control form-control-sm"
                    placeholder="Search name / email..."
                    value="<?= htmlspecialchars($search) ?>" 
                    style="width:220px;"
                >
            </div>

            <button class="btn btn-sm btn-primary">Search</button>

            <?php if ($search): ?>
                <a href="users.php" class="btn btn-sm btn-outline-secondary">Reset</a>
            <?php endif; ?>
        </form>
    </div>

    <div class="table-responsive">
        <table class="table align-middle mb-0">
            <thead>
                <tr>
                    <th>#</th>
                    <th>Name</th>
                    <th>Email</th>
                    <th>Role</th>
                    <th style="width:260px;">Action</th>
                </tr>
            </thead>

            <tbody>
                <?php if (empty($users)): ?>
                    <tr>
                        <td colspan="5" class="text-center text-muted py-4">
                            No users found
                        </td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($users as $i => $u): ?>
                        <tr>
                            <td><?= $i + 1 ?></td>

                            <td>
                                <strong><?= htmlspecialchars($u['name'] ?? '-') ?></strong>
                            </td>

                            <td>
                                <?= htmlspecialchars($u['email'] ?? '-') ?>
                            </td>

                            <td>
                                <span class="badge bg-light text-dark border">
                                    <?= htmlspecialchars($u['role'] ?? 'user') ?>
                                </span>
                            </td>

                            <td>
                                <div class="d-flex gap-2 align-items-center">
                                    <form method="POST" style="margin:0;">
                                        <input type="hidden" name="id_user" value="<?= (int)$u['id_user'] ?>">

                                        <select 
                                            name="role" 
                                            class="form-select form-select-sm" 
                                            onchange="this.form.submit()"
                                            style="width:110px;"
                                        >
                                            <option value="user" <?= ($u['role'] ?? '') === 'user' ? 'selected' : '' ?>>
                                                User
                                            </option>
                                            <option value="admin" <?= ($u['role'] ?? '') === 'admin' ? 'selected' : '' ?>>
                                                Admin
                                            </option>
                                        </select>

                                        <input type="hidden" name="update_role" value="1">
                                    </form>

                                    <form 
                                        method="POST" 
                                        style="margin:0;"
                                        onsubmit="return confirm('Delete this user? This action cannot be undone.');"
                                    >
                                        <input type="hidden" name="id_user" value="<?= (int)$u['id_user'] ?>">
                                        <button 
                                            type="submit" 
                                            name="delete_user" 
                                            class="btn btn-sm btn-outline-danger"
                                        >
                                            <i class="bi bi-trash3"></i>
                                        </button>
                                    </form>
                                </div>
                            </td>
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