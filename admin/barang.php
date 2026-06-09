<?php
require_once 'auth.php';
include 'koneksi.php';

$page_title = 'Product Data';
$active_menu = 'barang';
$msg = '';

// ADD PRODUCT
if (isset($_POST['tambah_barang'])) {
    $name     = $connect->real_escape_string(trim($_POST['name']));
    $id_cat   = (int)$_POST['id_category'];
    $id_user  = (int)$_POST['id_user'];
    $qty      = (int)$_POST['quantity'];
    $stok     = (int)$_POST['stok'];
    $price    = $connect->real_escape_string(trim(str_replace('.', '', $_POST['price'] ?? '0')));
    $unit     = $connect->real_escape_string(trim($_POST['unit'] ?? ''));
    $barcode  = $connect->real_escape_string(trim($_POST['barcode'] ?? ''));
    $exp      = $connect->real_escape_string(trim($_POST['expired_date'] ?? ''));
    $exp_val  = $exp ? "'$exp'" : "NULL";

    $connect->query("INSERT INTO item (id_category, id_user, name, quantity, stok, price, unit, barcode, expired_date)
                     VALUES ($id_cat, $id_user, '$name', $qty, $stok, '$price', '$unit', '$barcode', $exp_val)");
    $msg = '<div class="alert alert-success"><i class="bi bi-check-circle me-2"></i>Product added successfully.</div>';
}

// EDIT PRODUCT
if (isset($_POST['edit_barang'])) {
    $id       = (int)$_POST['id_item'];
    $name     = $connect->real_escape_string(trim($_POST['name']));
    $id_cat   = (int)$_POST['id_category'];
    $qty      = (int)$_POST['quantity'];
    $stok     = (int)$_POST['stok'];
    $price    = $connect->real_escape_string(trim(str_replace('.', '', $_POST['price'] ?? '0')));
    $unit     = $connect->real_escape_string(trim($_POST['unit'] ?? ''));
    $barcode  = $connect->real_escape_string(trim($_POST['barcode'] ?? ''));
    $exp      = $connect->real_escape_string(trim($_POST['expired_date'] ?? ''));
    $exp_val  = $exp ? "'$exp'" : "NULL";

    $connect->query("UPDATE item SET name='$name', id_category=$id_cat, quantity=$qty, stok=$stok,
                     price='$price', unit='$unit', barcode='$barcode', expired_date=$exp_val WHERE id_item=$id");
    $msg = '<div class="alert alert-success"><i class="bi bi-check-circle me-2"></i>Product updated successfully.</div>';
}

// DELETE PRODUCT
if (isset($_POST['hapus_barang'])) {
    $id = (int)$_POST['id_item'];
    $connect->query("DELETE FROM item WHERE id_item=$id");
    $msg = '<div class="alert alert-warning"><i class="bi bi-trash3 me-2"></i>Product deleted.</div>';
}

// FETCH categories & users for dropdown
$kategori = [];
$r = $connect->query("SELECT * FROM category ORDER BY name_category");
if($r) while($row=$r->fetch_assoc()) $kategori[] = $row;

$users = [];
$r = $connect->query("SELECT id_user, name FROM users ORDER BY name");
if($r) while($row=$r->fetch_assoc()) $users[] = $row;

// SEARCH + FILTER
$search  = isset($_GET['q'])      ? $connect->real_escape_string(trim($_GET['q'])) : '';
$fcat    = isset($_GET['cat'])    ? (int)$_GET['cat'] : 0;
$fstatus = isset($_GET['status']) ? $_GET['status']   : '';

$where_parts = [];
if($search)               $where_parts[] = "(i.name LIKE '%$search%' OR i.barcode LIKE '%$search%')";
if($fcat)                 $where_parts[] = "i.id_category=$fcat";
if($fstatus==='expired')  $where_parts[] = "i.expired_date < CURDATE()";
if($fstatus==='soon')     $where_parts[] = "i.expired_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)";
if($fstatus==='habis')    $where_parts[] = "i.quantity <= 0";
$where = $where_parts ? 'WHERE '.implode(' AND ',$where_parts) : '';

$items = [];
$r = $connect->query("SELECT i.*, c.name_category, u.name as user_name
                       FROM item i
                       LEFT JOIN category c ON i.id_category=c.id_category
                       LEFT JOIN users u ON i.id_user=u.id_user
                       $where
                       ORDER BY i.id_item DESC");
if($r) while($row=$r->fetch_assoc()) $items[] = $row;

// Edit mode
$edit_data = null;
if(isset($_GET['edit'])){
    $eid = (int)$_GET['edit'];
    $er = $connect->query("SELECT * FROM item WHERE id_item=$eid");
    if($er) $edit_data = $er->fetch_assoc();
}

ob_start();
?>

<?= $msg ?>

<div class="row g-3 mb-3">
    <div class="col-12">
        <form method="GET" class="d-flex flex-wrap gap-2 align-items-center">
            <div class="search-box">
                <i class="bi bi-search"></i>
                <input type="text" name="q" class="form-control" placeholder="Search name / barcode..." value="<?= htmlspecialchars($search) ?>" style="width:220px;">
            </div>
            <select name="cat" class="form-select" style="width:160px;">
                <option value="">All Categories</option>
                <?php foreach($kategori as $k): ?>
                <option value="<?= $k['id_category'] ?>" <?= $fcat==$k['id_category']?'selected':'' ?>><?= htmlspecialchars($k['name_category']) ?></option>
                <?php endforeach; ?>
            </select>
            <select name="status" class="form-select" style="width:150px;">
                <option value="">All Status</option>
                <option value="expired" <?= $fstatus==='expired'?'selected':'' ?>>Expired</option>
                <option value="soon"    <?= $fstatus==='soon'?'selected':'' ?>>Expiring Soon (7d)</option>
                <option value="habis"   <?= $fstatus==='habis'?'selected':'' ?>>Out of Stock</option>
            </select>
            <button class="btn btn-primary"><i class="bi bi-funnel me-1"></i>Filter</button>
            <a href="barang.php" class="btn btn-outline-secondary">Reset</a>
            <a href="barang.php?tambah=1" class="btn btn-success ms-auto"><i class="bi bi-plus-lg me-1"></i>Add Product</a>
        </form>
    </div>
</div>

<?php if(isset($_GET['tambah']) || $edit_data): ?>
<div class="table-wrap mb-3">
    <div class="card-header-custom">
        <span class="ch-title">
            <i class="bi bi-<?= $edit_data?'pencil-fill':'plus-circle-fill' ?> me-2 text-primary"></i>
            <?= $edit_data ? 'Edit Product' : 'Add Product' ?>
        </span>
        <a href="barang.php" class="btn btn-sm btn-outline-secondary">Close</a>
    </div>
    <div style="padding:20px;">
        <form method="POST">
            <?php if($edit_data): ?>
            <input type="hidden" name="id_item" value="<?= $edit_data['id_item'] ?>">
            <?php endif; ?>
            <div class="row g-3">
                <div class="col-md-6">
                    <label class="form-label">Product Name <span class="text-danger">*</span></label>
                    <input type="text" name="name" class="form-control" required value="<?= htmlspecialchars($edit_data['name']??'') ?>" placeholder="e.g. Instant Noodles">
                </div>
                <div class="col-md-3">
                    <label class="form-label">Category <span class="text-danger">*</span></label>
                    <select name="id_category" class="form-select" required>
                        <option value="">Select Category</option>
                        <?php foreach($kategori as $k): ?>
                        <option value="<?= $k['id_category'] ?>" <?= ($edit_data['id_category']??0)==$k['id_category']?'selected':'' ?>><?= htmlspecialchars($k['name_category']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <?php if(!$edit_data): ?>
                <div class="col-md-3">
                    <label class="form-label">Owned By</label>
                    <select name="id_user" class="form-select">
                        <option value="0">— Select User —</option>
                        <?php foreach($users as $u): ?>
                        <option value="<?= $u['id_user'] ?>"><?= htmlspecialchars($u['name']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <?php endif; ?>
                <div class="col-md-2">
                    <label class="form-label">Quantity</label>
                    <input type="number" name="quantity" class="form-control" min="0" value="<?= $edit_data['quantity']??1 ?>">
                </div>
                <div class="col-md-2">
                    <label class="form-label">Stock</label>
                    <input type="number" name="stok" class="form-control" min="0" value="<?= $edit_data['stok']??0 ?>">
                </div>
                <div class="col-md-2">
                    <label class="form-label">Price</label>
                    <div class="input-group">
                        <span class="input-group-text">Rp</span>
                        <input type="text" name="price" id="price" class="form-control" value="<?= number_format($edit_data['price']??0,0,',','.') ?>">
                    </div>
                </div>
                <div class="col-md-2">
                    <label class="form-label">Unit</label>
                    <select name="unit" class="form-select">
                        <option value="">Select Unit</option>
                        <?php foreach(['pcs','kg','liter','box','pack'] as $s): ?>
                        <option value="<?= $s ?>" <?= ($edit_data['unit']??'')===$s?'selected':'' ?>><?= $s ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="col-md-4">
                    <label class="form-label">Barcode</label>
                    <div style="position:relative;">
                        <i class="bi bi-upc-scan" style="position:absolute;left:11px;top:50%;transform:translateY(-50%);color:var(--muted);"></i>
                        <input type="text" name="barcode" class="form-control" style="padding-left:34px;" value="<?= htmlspecialchars($edit_data['barcode']??'') ?>" placeholder="Scan or type manually">
                    </div>
                </div>
                <div class="col-md-3">
                    <label class="form-label">Expiry Date</label>
                    <input type="date" name="expired_date" class="form-control" value="<?= $edit_data['expired_date']??'' ?>">
                </div>
            </div>
            <div class="mt-3 d-flex gap-2">
                <?php if($edit_data): ?>
                <button name="edit_barang" class="btn btn-primary"><i class="bi bi-check-lg me-1"></i>Update Product</button>
                <?php else: ?>
                <button name="tambah_barang" class="btn btn-primary"><i class="bi bi-plus-lg me-1"></i>Save Product</button>
                <?php endif; ?>
                <a href="barang.php" class="btn btn-outline-secondary">Cancel</a>
            </div>
        </form>
    </div>
</div>
<?php endif; ?>

<div class="table-wrap">
    <div class="card-header-custom">
        <span class="ch-title"><i class="bi bi-basket3-fill me-2 text-primary"></i>Product List (<?= count($items) ?>)</span>
    </div>
    <div style="overflow-x:auto;">
    <table class="table">
        <thead>
            <tr>
                <th>#</th><th>Product Name</th><th>Category</th><th>Stock / Qty</th>
                <th>Price</th><th>Barcode</th><th>Expiry</th><th>User</th><th>Status</th><th>Action</th>
            </tr>
        </thead>
<tbody>
    <?php if(empty($items)): ?>
        <tr>
            <td colspan="10" class="text-center text-muted py-4">No data found</td>
        </tr>
    <?php else: foreach($items as $i => $item):
        $exp = $item['expired_date'] ?? null;
        $label = 'Safe';

        if (($item['quantity'] ?? 1) <= 0) {
            $label = 'Out of Stock';
        } elseif ($exp) {
            $diff = (strtotime($exp) - time()) / 86400;

            if ($diff < 0) {
                $label = 'Expired';
            } elseif ($diff <= 7) {
                $label = 'Expiring Soon';
            }
        }
    ?>
        <tr>
            <td><?= $i + 1 ?></td>
            <td><strong><?= htmlspecialchars($item['name']) ?></strong></td>
            <td><?= htmlspecialchars($item['name_category'] ?? '-') ?></td>
            <td><?= ($item['stok'] ?? 0) ?> / <?= ($item['quantity'] ?? 0) ?> <?= htmlspecialchars($item['unit'] ?? '') ?></td>
            <td>Rp<?= number_format($item['price'] ?? 0, 0, ',', '.') ?></td>
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
            <td><?= htmlspecialchars($item['user_name'] ?? '-') ?></td>
            <td><?= $label ?></td>
            <td>
                <div class="d-flex gap-1">
                    <a href="barang.php?edit=<?= $item['id_item'] ?>" class="btn btn-sm btn-warning">
                        Edit
                    </a>

                    <form method="POST" onsubmit="return confirm('Delete this product?')">
                        <input type="hidden" name="id_item" value="<?= $item['id_item'] ?>">
                        <button name="hapus_barang" class="btn btn-sm btn-danger">
                            Delete
                        </button>
                    </form>
                </div>
            </td>
        </tr>
    <?php endforeach; endif; ?>
</tbody>
    </table>
    </div>
</div>

<script>
const priceInput = document.getElementById('price');
if(priceInput){
    priceInput.addEventListener('input', function() {
        let value = this.value.replace(/[^0-9]/g, '');
        this.value = new Intl.NumberFormat('id-ID').format(value);
    });
}
</script>

<?php
$content = ob_get_clean();
include 'layout.php';
?>
