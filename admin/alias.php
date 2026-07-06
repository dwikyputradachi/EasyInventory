<?php
require_once 'auth.php';
include 'koneksi.php';

$page_title  = 'Product Alias';
$active_menu = 'alias';

$msg = '';

function clean($db, $value) {
    return $db->real_escape_string(trim($value));
}

// ===============================
// ADD ALIAS
// ===============================
if (isset($_POST['add_alias'])) {
    $generic_name = clean($connect, $_POST['generic_name'] ?? '');
    $alias_name   = clean($connect, $_POST['alias_name'] ?? '');
    $id_category  = isset($_POST['id_category']) && $_POST['id_category'] !== ''
        ? (int)$_POST['id_category']
        : null;

    if ($generic_name === '' || $alias_name === '') {
        $msg = '<div class="alert alert-danger">Generic name and alias name are required.</div>';
    } else {
        $checkSql = "
            SELECT id_alias 
            FROM product_alias
            WHERE LOWER(generic_name) = LOWER('$generic_name')
            AND LOWER(alias_name) = LOWER('$alias_name')
            LIMIT 1
        ";

        $check = $connect->query($checkSql);

        if ($check && $check->num_rows > 0) {
            $msg = '<div class="alert alert-warning">Alias already exists.</div>';
        } else {
            if ($id_category === null) {
                $sql = "
                    INSERT INTO product_alias (generic_name, alias_name, id_category)
                    VALUES ('$generic_name', '$alias_name', NULL)
                ";
            } else {
                $sql = "
                    INSERT INTO product_alias (generic_name, alias_name, id_category)
                    VALUES ('$generic_name', '$alias_name', $id_category)
                ";
            }

            if ($connect->query($sql)) {
                $msg = '<div class="alert alert-success">Product alias added successfully.</div>';
            } else {
                $msg = '<div class="alert alert-danger">Failed to add alias: ' . htmlspecialchars($connect->error) . '</div>';
            }
        }
    }
}

// ===============================
// UPDATE ALIAS
// ===============================
if (isset($_POST['update_alias'])) {
    $id_alias     = (int)($_POST['id_alias'] ?? 0);
    $generic_name = clean($connect, $_POST['generic_name'] ?? '');
    $alias_name   = clean($connect, $_POST['alias_name'] ?? '');
    $id_category  = isset($_POST['id_category']) && $_POST['id_category'] !== ''
        ? (int)$_POST['id_category']
        : null;

    if ($id_alias <= 0 || $generic_name === '' || $alias_name === '') {
        $msg = '<div class="alert alert-danger">Invalid alias data.</div>';
    } else {
        if ($id_category === null) {
            $sql = "
                UPDATE product_alias
                SET generic_name = '$generic_name',
                    alias_name = '$alias_name',
                    id_category = NULL
                WHERE id_alias = $id_alias
            ";
        } else {
            $sql = "
                UPDATE product_alias
                SET generic_name = '$generic_name',
                    alias_name = '$alias_name',
                    id_category = $id_category
                WHERE id_alias = $id_alias
            ";
        }

        if ($connect->query($sql)) {
            $msg = '<div class="alert alert-success">Alias updated successfully.</div>';
        } else {
            $msg = '<div class="alert alert-danger">Failed to update alias: ' . htmlspecialchars($connect->error) . '</div>';
        }
    }
}

// ===============================
// DELETE ALIAS
// ===============================
if (isset($_POST['delete_alias'])) {
    $id_alias = (int)($_POST['id_alias'] ?? 0);

    if ($id_alias > 0) {
        if ($connect->query("DELETE FROM product_alias WHERE id_alias = $id_alias")) {
            $msg = '<div class="alert alert-warning">Alias deleted successfully.</div>';
        } else {
            $msg = '<div class="alert alert-danger">Failed to delete alias: ' . htmlspecialchars($connect->error) . '</div>';
        }
    }
}

// ===============================
// DATA
// ===============================
$search = isset($_GET['q']) ? clean($connect, $_GET['q']) : '';

$where = '';
if ($search !== '') {
    $where = "
        WHERE pa.generic_name LIKE '%$search%'
        OR pa.alias_name LIKE '%$search%'
        OR c.name_category LIKE '%$search%'
    ";
}

$categories = [];
$r = $connect->query("
    SELECT id_category, name_category
    FROM category
    ORDER BY name_category
");
if ($r) {
    while ($row = $r->fetch_assoc()) {
        $categories[] = $row;
    }
}

$aliases = [];
$r = $connect->query("
    SELECT 
        pa.id_alias,
        pa.generic_name,
        pa.alias_name,
        pa.id_category,
        pa.created_at,
        c.name_category
    FROM product_alias pa
    LEFT JOIN category c ON pa.id_category = c.id_category
    $where
    ORDER BY pa.generic_name ASC, pa.alias_name ASC
");
if ($r) {
    while ($row = $r->fetch_assoc()) {
        $aliases[] = $row;
    }
}

ob_start();
?>

<?= $msg ?>

<div class="alert alert-light border" style="font-size:13px;">
    <i class="bi bi-info-circle-fill text-primary me-1"></i>
    Product Alias is used for Shopping List matching, for example <strong>Dancow = susu</strong>.
    OCR Keywords are still used only for category classification.
</div>

<!-- ADD FORM -->
<div class="table-wrap mb-3">
    <div class="card-header-custom">
        <span class="ch-title">
            <i class="bi bi-plus-circle-fill me-2 text-primary"></i>
            Add Product Alias
        </span>
    </div>

    <form method="POST" class="row g-2 p-3">
        <div class="col-md-3">
            <label class="form-label" style="font-size:12px;font-weight:600;">Generic Name</label>
            <input 
                type="text" 
                name="generic_name" 
                class="form-control" 
                placeholder="Example: susu"
                required
            >
        </div>

        <div class="col-md-3">
            <label class="form-label" style="font-size:12px;font-weight:600;">Alias Name</label>
            <input 
                type="text" 
                name="alias_name" 
                class="form-control" 
                placeholder="Example: dancow"
                required
            >
        </div>

        <div class="col-md-3">
            <label class="form-label" style="font-size:12px;font-weight:600;">Category Optional</label>
            <select name="id_category" class="form-select">
                <option value="">No Category</option>
                <?php foreach ($categories as $cat): ?>
                    <option value="<?= (int)$cat['id_category'] ?>">
                        <?= htmlspecialchars($cat['name_category']) ?>
                    </option>
                <?php endforeach; ?>
            </select>
        </div>

        <div class="col-md-3 d-flex align-items-end">
            <button type="submit" name="add_alias" class="btn btn-primary w-100">
                <i class="bi bi-save me-1"></i>
                Save Alias
            </button>
        </div>
    </form>
</div>

<!-- SEARCH -->
<form method="GET" class="d-flex flex-wrap gap-2 mb-3 align-items-center">
    <div class="search-box">
        <i class="bi bi-search"></i>
        <input 
            type="text" 
            name="q" 
            class="form-control" 
            placeholder="Search alias..."
            value="<?= htmlspecialchars($search) ?>"
            style="width:240px;"
        >
    </div>

    <button class="btn btn-primary">
        <i class="bi bi-search me-1"></i>
        Search
    </button>

    <a href="alias.php" class="btn btn-outline-secondary">
        Reset
    </a>

    <span class="text-muted ms-auto" style="font-size:13px;">
        <?= count($aliases) ?> aliases found
    </span>
</form>

<!-- TABLE -->
<div class="table-wrap">
    <div class="card-header-custom">
        <span class="ch-title">
            <i class="bi bi-diagram-3-fill me-2 text-primary"></i>
            Product Alias List
        </span>
    </div>

    <div class="table-responsive">
        <table class="table align-middle mb-0">
            <thead>
                <tr>
                    <th>#</th>
                    <th>Generic Name</th>
                    <th>Alias Name</th>
                    <th>Category</th>
                    <th>Created</th>
                    <th style="width:280px;">Action</th>
                </tr>
            </thead>

            <tbody>
                <?php if (empty($aliases)): ?>
                    <tr>
                        <td colspan="6" class="text-center text-muted py-4">
                            No alias data found
                        </td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($aliases as $i => $a): ?>
                        <tr>
                            <td><?= $i + 1 ?></td>

                            <td>
                                <strong><?= htmlspecialchars($a['generic_name']) ?></strong>
                            </td>

                            <td>
                                <?= htmlspecialchars($a['alias_name']) ?>
                            </td>

                            <td>
                                <?php if (!empty($a['name_category'])): ?>
                                    <span class="badge bg-light text-dark border">
                                        <?= htmlspecialchars($a['name_category']) ?>
                                    </span>
                                <?php else: ?>
                                    <span class="text-muted">-</span>
                                <?php endif; ?>
                            </td>

                            <td>
                                <?= !empty($a['created_at'])
                                    ? date('d M Y', strtotime($a['created_at']))
                                    : '<span class="text-muted">-</span>' ?>
                            </td>

                            <td>
                                <div class="d-flex gap-2">
                                    <button 
                                        type="button"
                                        class="btn btn-sm btn-outline-primary"
                                        data-bs-toggle="modal"
                                        data-bs-target="#editAlias<?= (int)$a['id_alias'] ?>"
                                    >
                                        <i class="bi bi-pencil-square"></i>
                                    </button>

                                    <form 
                                        method="POST"
                                        onsubmit="return confirm('Delete this alias?');"
                                        style="margin:0;"
                                    >
                                        <input type="hidden" name="id_alias" value="<?= (int)$a['id_alias'] ?>">
                                        <button type="submit" name="delete_alias" class="btn btn-sm btn-outline-danger">
                                            <i class="bi bi-trash3"></i>
                                        </button>
                                    </form>
                                </div>

                                <!-- EDIT MODAL -->
                                <div class="modal fade" id="editAlias<?= (int)$a['id_alias'] ?>" tabindex="-1">
                                    <div class="modal-dialog">
                                        <div class="modal-content">
                                            <form method="POST">
                                                <div class="modal-header">
                                                    <h5 class="modal-title">Edit Alias</h5>
                                                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                                </div>

                                                <div class="modal-body">
                                                    <input type="hidden" name="id_alias" value="<?= (int)$a['id_alias'] ?>">

                                                    <div class="mb-3">
                                                        <label class="form-label">Generic Name</label>
                                                        <input 
                                                            type="text" 
                                                            name="generic_name" 
                                                            class="form-control"
                                                            value="<?= htmlspecialchars($a['generic_name']) ?>"
                                                            required
                                                        >
                                                    </div>

                                                    <div class="mb-3">
                                                        <label class="form-label">Alias Name</label>
                                                        <input 
                                                            type="text" 
                                                            name="alias_name" 
                                                            class="form-control"
                                                            value="<?= htmlspecialchars($a['alias_name']) ?>"
                                                            required
                                                        >
                                                    </div>

                                                    <div class="mb-3">
                                                        <label class="form-label">Category Optional</label>
                                                        <select name="id_category" class="form-select">
                                                            <option value="">No Category</option>
                                                            <?php foreach ($categories as $cat): ?>
                                                                <option 
                                                                    value="<?= (int)$cat['id_category'] ?>"
                                                                    <?= (int)($a['id_category'] ?? 0) === (int)$cat['id_category'] ? 'selected' : '' ?>
                                                                >
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
                                                    <button type="submit" name="update_alias" class="btn btn-primary">
                                                        Save Changes
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