<?php
require_once 'auth.php';
include 'koneksi.php';

$page_title  = 'Unmatched Product';
$active_menu = 'unmatched_alias';

$msg = '';

function clean($db, $value) {
    return $db->real_escape_string(trim($value));
}

// Resolve: jadikan product_alias
if (isset($_POST['resolve_alias'])) {
    $id_unmatched = (int)($_POST['id_unmatched'] ?? 0);
    $generic_name = clean($connect, $_POST['generic_name'] ?? '');
    $alias_name   = clean($connect, $_POST['alias_name'] ?? '');
    $id_category  = isset($_POST['id_category']) && $_POST['id_category'] !== ''
        ? (int)$_POST['id_category']
        : null;

    if ($id_unmatched <= 0 || $generic_name === '' || $alias_name === '') {
        $msg = '<div class="alert alert-danger">Data tidak lengkap.</div>';
    } else {
        $check = $connect->query("
            SELECT id_alias
            FROM product_alias
            WHERE LOWER(generic_name) = LOWER('$generic_name')
            AND LOWER(alias_name) = LOWER('$alias_name')
            LIMIT 1
        ");

        if ($check && $check->num_rows == 0) {
            if ($id_category === null) {
                $connect->query("
                    INSERT INTO product_alias (generic_name, alias_name, id_category)
                    VALUES ('$generic_name', '$alias_name', NULL)
                ");
            } else {
                $connect->query("
                    INSERT INTO product_alias (generic_name, alias_name, id_category)
                    VALUES ('$generic_name', '$alias_name', $id_category)
                ");
            }
        }

        $update = $connect->query("
            UPDATE unmatched_product_alias
            SET 
                suggested_generic_name = '$generic_name',
                status = 'resolved'
            WHERE id_unmatched = $id_unmatched
        ");

        if ($update) {
            $msg = '<div class="alert alert-success">Produk berhasil dijadikan alias.</div>';
        } else {
            $msg = '<div class="alert alert-danger">Gagal resolve alias: ' . htmlspecialchars($connect->error) . '</div>';
        }
    }
}

// Ignore
if (isset($_POST['ignore_alias'])) {
    $id_unmatched = (int)($_POST['id_unmatched'] ?? 0);

    if ($id_unmatched > 0) {
        $connect->query("
            UPDATE unmatched_product_alias
            SET status = 'ignored'
            WHERE id_unmatched = $id_unmatched
        ");

        $msg = '<div class="alert alert-warning">Produk diabaikan.</div>';
    }
}

// Delete
if (isset($_POST['delete_alias'])) {
    $id_unmatched = (int)($_POST['id_unmatched'] ?? 0);

    if ($id_unmatched > 0) {
        $connect->query("
            DELETE FROM unmatched_product_alias
            WHERE id_unmatched = $id_unmatched
        ");

        $msg = '<div class="alert alert-danger">Data unmatched dihapus.</div>';
    }
}

$categories = [];
$catResult = $connect->query("
    SELECT id_category, name_category
    FROM category
    ORDER BY name_category ASC
");

if ($catResult) {
    while ($row = $catResult->fetch_assoc()) {
        $categories[] = $row;
    }
}

$status = $_GET['status'] ?? 'pending';
$search = isset($_GET['q']) ? clean($connect, $_GET['q']) : '';

$where = "WHERE upa.status = '$status'";

if ($search !== '') {
    $where .= " AND upa.product_name LIKE '%$search%'";
}

$data = [];
$result = $connect->query("
    SELECT 
        upa.id_unmatched,
        upa.id_user,
        upa.product_name,
        upa.suggested_generic_name,
        upa.status,
        upa.created_at,
        u.name AS user_name,
        u.email AS user_email
    FROM unmatched_product_alias upa
    LEFT JOIN users u ON upa.id_user = u.id_user
    $where
    ORDER BY upa.created_at DESC
");

if ($result) {
    while ($row = $result->fetch_assoc()) {
        $data[] = $row;
    }
}

ob_start();
?>

<?= $msg ?>

<div class="alert alert-light border" style="font-size:13px;">
    <i class="bi bi-info-circle-fill text-primary me-1"></i>
    Halaman ini menampilkan produk yang masuk inventory tapi belum cocok dengan shopping list alias.
    Admin bisa menjadikannya alias baru, contoh <strong>Milo Cereal → susu</strong>.
</div>

<form method="GET" class="d-flex flex-wrap gap-2 mb-3 align-items-center">
    <div class="search-box">
        <i class="bi bi-search"></i>
        <input 
            type="text" 
            name="q" 
            class="form-control" 
            placeholder="Search product..."
            value="<?= htmlspecialchars($search) ?>"
            style="width:240px;"
        >
    </div>

    <select name="status" class="form-select" style="width:160px;">
        <option value="pending" <?= $status === 'pending' ? 'selected' : '' ?>>Pending</option>
        <option value="resolved" <?= $status === 'resolved' ? 'selected' : '' ?>>Resolved</option>
        <option value="ignored" <?= $status === 'ignored' ? 'selected' : '' ?>>Ignored</option>
    </select>

    <button class="btn btn-primary">
        <i class="bi bi-search me-1"></i>
        Filter
    </button>

    <a href="unmatched_alias.php" class="btn btn-outline-secondary">
        Reset
    </a>

    <span class="text-muted ms-auto" style="font-size:13px;">
        <?= count($data) ?> data found
    </span>
</form>

<div class="table-wrap">
    <div class="card-header-custom">
        <span class="ch-title">
            <i class="bi bi-question-circle-fill me-2 text-primary"></i>
            Unmatched Product List
        </span>
    </div>

    <div class="table-responsive">
        <table class="table align-middle mb-0">
            <thead>
                <tr>
                    <th>#</th>
                    <th>Product Name</th>
                    <th>User</th>
                    <th>Status</th>
                    <th>Created</th>
                    <th style="width:330px;">Action</th>
                </tr>
            </thead>

            <tbody>
                <?php if (empty($data)): ?>
                    <tr>
                        <td colspan="6" class="text-center text-muted py-4">
                            No unmatched product found
                        </td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($data as $i => $row): ?>
                        <tr>
                            <td><?= $i + 1 ?></td>

                            <td>
                                <strong><?= htmlspecialchars($row['product_name']) ?></strong>
                                <?php if (!empty($row['suggested_generic_name'])): ?>
                                    <br>
                                    <small class="text-muted">
                                        Resolved as: <?= htmlspecialchars($row['suggested_generic_name']) ?>
                                    </small>
                                <?php endif; ?>
                            </td>

                            <td>
                                <?php if (!empty($row['user_name'])): ?>
                                    <?= htmlspecialchars($row['user_name']) ?>
                                    <br>
                                    <small class="text-muted"><?= htmlspecialchars($row['user_email']) ?></small>
                                <?php else: ?>
                                    <span class="text-muted">Unknown user</span>
                                <?php endif; ?>
                            </td>

                            <td>
                                <?php if ($row['status'] === 'pending'): ?>
                                    <span class="badge bg-warning text-dark">Pending</span>
                                <?php elseif ($row['status'] === 'resolved'): ?>
                                    <span class="badge bg-success">Resolved</span>
                                <?php else: ?>
                                    <span class="badge bg-secondary">Ignored</span>
                                <?php endif; ?>
                            </td>

                            <td>
                                <?= date('d M Y H:i', strtotime($row['created_at'])) ?>
                            </td>

                            <td>
                                <div class="d-flex gap-2">
                                    <?php if ($row['status'] === 'pending'): ?>
                                        <button 
                                            type="button"
                                            class="btn btn-sm btn-primary"
                                            data-bs-toggle="modal"
                                            data-bs-target="#resolveModal<?= (int)$row['id_unmatched'] ?>"
                                        >
                                            Resolve
                                        </button>

                                        <form method="POST" style="margin:0;">
                                            <input type="hidden" name="id_unmatched" value="<?= (int)$row['id_unmatched'] ?>">
                                            <button 
                                                type="submit" 
                                                name="ignore_alias" 
                                                class="btn btn-sm btn-outline-secondary"
                                            >
                                                Ignore
                                            </button>
                                        </form>
                                    <?php endif; ?>

                                    <form 
                                        method="POST" 
                                        style="margin:0;"
                                        onsubmit="return confirm('Delete this unmatched product?');"
                                    >
                                        <input type="hidden" name="id_unmatched" value="<?= (int)$row['id_unmatched'] ?>">
                                        <button type="submit" name="delete_alias" class="btn btn-sm btn-outline-danger">
                                            <i class="bi bi-trash3"></i>
                                        </button>
                                    </form>
                                </div>

                                <div class="modal fade" id="resolveModal<?= (int)$row['id_unmatched'] ?>" tabindex="-1">
                                    <div class="modal-dialog">
                                        <div class="modal-content">
                                            <form method="POST">
                                                <div class="modal-header">
                                                    <h5 class="modal-title">Resolve Product Alias</h5>
                                                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                                </div>

                                                <div class="modal-body">
                                                    <input type="hidden" name="id_unmatched" value="<?= (int)$row['id_unmatched'] ?>">

                                                    <div class="mb-3">
                                                        <label class="form-label">Alias Name</label>
                                                        <input 
                                                            type="text" 
                                                            name="alias_name" 
                                                            class="form-control"
                                                            value="<?= htmlspecialchars($row['product_name']) ?>"
                                                            required
                                                        >
                                                        <small class="text-muted">
                                                            Ini nama produk yang masuk inventory.
                                                        </small>
                                                    </div>

                                                    <div class="mb-3">
                                                        <label class="form-label">Generic Name</label>
                                                        <input 
                                                            type="text" 
                                                            name="generic_name" 
                                                            class="form-control"
                                                            placeholder="Example: susu, mie, snack"
                                                            required
                                                        >
                                                        <small class="text-muted">
                                                            Ini nama umum yang ada di shopping list.
                                                        </small>
                                                    </div>

                                                    <div class="mb-3">
                                                        <label class="form-label">Category Optional</label>
                                                        <select name="id_category" class="form-select">
                                                            <option value="">No Category</option>
                                                            <?php foreach ($categories as $cat): ?>
                                                                <option value="<?= (int)$cat['id_category'] ?>">
                                                                    <?= htmlspecialchars($cat['name_category']) ?>
                                                                </option>
                                                            <?php endforeach; ?>
                                                        </select>
                                                    </div>
                                                </div>

                                                <div class="modal-footer">
                                                    <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">
                                                        Cancel
                                                    </button>
                                                    <button type="submit" name="resolve_alias" class="btn btn-primary">
                                                        Save as Alias
                                                    </button>
                                                </div>
                                            </form>
                                        </div>
                                    </div>
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