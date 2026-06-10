<?php
require_once 'auth.php';
include 'koneksi.php';
$page_title  = 'Category & OCR Keyword';
$active_menu = 'kategori';
$msg = '';

// ADD
if (isset($_POST['tambah_kategori'])) {
    $name = $connect->real_escape_string(trim($_POST['name_category']));
    $kw   = $connect->real_escape_string(trim($_POST['ocr_keywords'] ?? ''));
    if ($name) {
        $connect->query("INSERT INTO category (name_category, ocr_keywords) VALUES ('$name','$kw')");
        $msg = ['type' => 'success', 'text' => 'Category added successfully.'];
    }
}

// EDIT
if (isset($_POST['edit_kategori'])) {
    $id   = (int)$_POST['id_category'];
    $name = $connect->real_escape_string(trim($_POST['name_category']));
    $kw   = $connect->real_escape_string(trim($_POST['ocr_keywords'] ?? ''));
    $connect->query("UPDATE category SET name_category='$name', ocr_keywords='$kw' WHERE id_category=$id");
    $msg = ['type' => 'success', 'text' => 'Category updated successfully.'];
}

// DELETE
if (isset($_POST['hapus_kategori'])) {
    $id = (int)$_POST['id_category'];
    $connect->query("DELETE FROM category WHERE id_category=$id");
    $msg = ['type' => 'warning', 'text' => 'Category deleted.'];
}

// FETCH
$r = $connect->query("SELECT * FROM category ORDER BY id_category DESC");
$kategori = $r ? $r->fetch_all(MYSQLI_ASSOC) : [];

// Edit mode
$edit_data = null;
if (isset($_GET['edit'])) {
    $eid = (int)$_GET['edit'];
    $er  = $connect->query("SELECT * FROM category WHERE id_category=$eid");
    if ($er) $edit_data = $er->fetch_assoc();
}

ob_start();
?>

<?php if ($msg): ?>
<div class="alert alert-<?= $msg['type'] ?>">
    <i class="bi bi-<?= $msg['type'] === 'success' ? 'check-circle' : 'trash3' ?> me-2"></i><?= $msg['text'] ?>
</div>
<?php endif; ?>

<div class="row g-3">

    <!-- ── ADD / EDIT FORM ── -->
    <div class="col-lg-4">
        <div class="table-wrap">
            <div class="card-header-custom">
                <span class="ch-title">
                    <i class="bi bi-<?= $edit_data ? 'pencil-fill' : 'plus-circle-fill' ?> me-2 text-primary"></i>
                    <?= $edit_data ? 'Edit Category' : 'Add Category' ?>
                </span>
            </div>
            <div style="padding:20px;">
                <form method="POST">
                    <?php if ($edit_data): ?>
                        <input type="hidden" name="id_category" value="<?= $edit_data['id_category'] ?>">
                    <?php endif; ?>

                    <div class="mb-3">
                        <label class="form-label">Category Name</label>
                        <input type="text" name="name_category" class="form-control"
                               value="<?= htmlspecialchars($edit_data['name_category'] ?? '') ?>"
                               placeholder="e.g. Food, Beverage..." required>
                    </div>

                    <div class="mb-3">
                        <label class="form-label">
                            OCR Keywords
                            <small class="text-muted fw-normal"> — separate with commas</small>
                        </label>
                        <textarea name="ocr_keywords" class="form-control" rows="4"
                                  placeholder="e.g. noodles, fried noodles, rice, sugar..."
                                  style="resize:vertical;"><?= htmlspecialchars($edit_data['ocr_keywords'] ?? '') ?></textarea>
                        <div class="form-text"><i class="bi bi-info-circle me-1"></i>Used by OCR to categorize items from scanned receipts.</div>
                    </div>

                    <div class="d-flex gap-2">
                        <?php if ($edit_data): ?>
                            <button name="edit_kategori" class="btn btn-primary flex-fill"><i class="bi bi-check-lg me-1"></i>Update</button>
                            <a href="kategori.php" class="btn btn-outline-secondary">Cancel</a>
                        <?php else: ?>
                            <button name="tambah_kategori" class="btn btn-primary flex-fill"><i class="bi bi-plus-lg me-1"></i>Add</button>
                        <?php endif; ?>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- ── CATEGORY LIST ── -->
    <div class="col-lg-8">
        <div class="table-wrap">
            <div class="card-header-custom">
                <span class="ch-title"><i class="bi bi-tags-fill me-2" style="color:#8b5cf6;"></i>Category List (<?= count($kategori) ?>)</span>
            </div>
            <table class="table">
                <thead>
                    <tr><th>#</th><th>Category Name</th><th>OCR Keywords</th><th>Action</th></tr>
                </thead>
                <tbody>
                <?php if (empty($kategori)): ?>
                    <tr><td colspan="4" class="text-center text-muted py-4">No categories yet</td></tr>
                <?php else: foreach ($kategori as $i => $k):
                    $kws   = array_filter(array_map('trim', explode(',', $k['ocr_keywords'] ?? '')));
                    $shown = array_slice($kws, 0, 4);
                    $extra = count($kws) - count($shown);
                ?>
                    <tr>
                        <td class="text-muted" style="font-size:12px;"><?= $i + 1 ?></td>
                        <td><strong><?= htmlspecialchars($k['name_category']) ?></strong></td>
                        <td>
    <?php if ($shown): ?>
        <span style="font-size:13px; color:var(--bs-secondary-color);">
            <?= htmlspecialchars(implode(', ', $shown)) ?>
            <?php if ($extra > 0): ?>
                <span style="font-size:11px; color:var(--bs-gray-500);">+<?= $extra ?> more</span>
            <?php endif; ?>
        </span>
    <?php else: ?>
        <span class="text-muted">—</span>
    <?php endif; ?>
</td>
                        <td>
                            <div class="d-flex gap-1">
                                <a href="kategori.php?edit=<?= $k['id_category'] ?>" class="btn btn-sm btn-warning">
                                    <i class="bi bi-pencil"></i>
                                </a>
                                <form method="POST" onsubmit="return confirm('Delete category <?= htmlspecialchars($k['name_category']) ?>?')">
                                    <input type="hidden" name="id_category" value="<?= $k['id_category'] ?>">
                                    <button name="hapus_kategori" class="btn btn-sm btn-danger"><i class="bi bi-trash3"></i></button>
                                </form>
                            </div>
                        </td>
                    </tr>
                <?php endforeach; endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>



<?php
$content = ob_get_clean();
include 'layout.php';
?>
