<?php
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

if (!isset($page_title)) {
    $page_title = 'Easy Inventory Admin';
}

if (!isset($active_menu)) {
    $active_menu = '';
}

$admin_name = $_SESSION['admin']['name'] ?? 'Administrator';

$nav_main = [
    ['href' => 'index.php', 'menu' => 'dashboard', 'icon' => 'speedometer2', 'label' => 'Dashboard'],
];

$nav_manajemen = [
    ['href' => 'users.php', 'menu' => 'users', 'icon' => 'people-fill', 'label' => 'User Manage'],
    ['href' => 'kategori.php', 'menu' => 'kategori', 'icon' => 'tags-fill', 'label' => 'Category & OCR Keyword'],
    ['href' => 'barang.php', 'menu' => 'barang', 'icon' => 'basket3-fill', 'label' => 'Product Data'],
];

$nav_monitoring = [
    ['href' => 'inventaris.php', 'menu' => 'inventaris', 'icon' => 'clipboard2-data-fill', 'label' => 'Monitor Inventaris'],
    ['href' => 'expired.php', 'menu' => 'expired', 'icon' => 'exclamation-triangle-fill', 'label' => 'Expired Items', 'badge' => true],
];

$expired_badge = 0;
if (isset($connect)) {
    $r = $connect->query("
        SELECT COUNT(*) c 
        FROM item 
        WHERE expired_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)
    ");
    if ($r) {
        $expired_badge = (int)$r->fetch_assoc()['c'];
    }
}

function navLink($item, $active_menu, $badge = 0) {
    $cls = $active_menu === $item['menu'] ? ' active' : '';

    echo "<a href='{$item['href']}' class='$cls'>";
    echo "<i class='bi bi-{$item['icon']}'></i> {$item['label']}";

    if (!empty($item['badge']) && $badge > 0) {
        echo "<span class='badge-count'>$badge</span>";
    }

    echo "</a>";
}
?>

<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<title><?= htmlspecialchars($page_title) ?> — Easy Inventory</title>

<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700;800&family=Space+Mono:wght@400;700&display=swap" rel="stylesheet">

<style>
:root {
    --sw: 255px;
    --primary: #16a34a;
    --primary-h: #15803d;
    --primary-light: #dcfce7;
    --accent: #f59e0b;
    --danger: #ef4444;
    --warn: #f97316;
    --info: #3b82f6;
    --bg: #f0fdf4;
    --surface: #ffffff;
    --border: #e2e8f0;
    --text: #0f172a;
    --muted: #64748b;
    --sidebar-bg: #0d1f13;
    --sidebar-text: #a3c9a8;
    --sidebar-active-bg: #16a34a;
    --sidebar-active-text: #ffffff;
    --sidebar-hover-bg: rgba(22,163,74,.15);
}

*, *::before, *::after {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
}

body {
    font-family: 'Plus Jakarta Sans', sans-serif;
    background: var(--bg);
    color: var(--text);
    min-height: 100vh;
    display: flex;
}

.sidebar {
    width: var(--sw);
    flex-shrink: 0;
    background: var(--sidebar-bg);
    min-height: 100vh;
    position: fixed;
    top: 0;
    left: 0;
    display: flex;
    flex-direction: column;
    z-index: 1000;
    transition: transform .25s ease;
}

.sidebar-brand {
    padding: 24px 20px 18px;
    border-bottom: 1px solid rgba(255,255,255,.07);
    display: flex;
    align-items: center;
    gap: 10px;
}

.sidebar-brand .brand-icon {
    width: 36px;
    height: 36px;
    background: var(--primary);
    border-radius: 10px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 18px;
    color: #fff;
}

.sidebar-brand .brand-name {
    font-size: 15px;
    font-weight: 800;
    color: #fff;
}

.sidebar-section-label {
    font-size: 10px;
    font-weight: 700;
    letter-spacing: 1.5px;
    color: rgba(163,201,168,.45);
    text-transform: uppercase;
    padding: 18px 20px 6px;
}

.sidebar nav {
    padding: 8px 12px;
    flex: 1;
    overflow-y: auto;
}

.sidebar nav a {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 10px 12px;
    border-radius: 9px;
    color: var(--sidebar-text);
    text-decoration: none;
    font-size: 13.5px;
    font-weight: 500;
    margin-bottom: 2px;
}

.sidebar nav a i {
    font-size: 16px;
    width: 20px;
    text-align: center;
}

.sidebar nav a:hover {
    background: var(--sidebar-hover-bg);
    color: #fff;
}

.sidebar nav a.active {
    background: var(--sidebar-active-bg);
    color: var(--sidebar-active-text);
    font-weight: 600;
}

.badge-count {
    margin-left: auto;
    background: var(--accent);
    color: #fff;
    font-size: 10px;
    font-weight: 700;
    border-radius: 20px;
    padding: 1px 7px;
}

.sidebar-footer {
    padding: 14px 16px;
    border-top: 1px solid rgba(255,255,255,.07);
}

.sidebar-footer a {
    display: flex;
    align-items: center;
    gap: 9px;
    color: rgba(163,201,168,.6);
    font-size: 13px;
    text-decoration: none;
    padding: 8px 10px;
    border-radius: 8px;
}

.sidebar-footer a:hover {
    background: rgba(239,68,68,.15);
    color: #ef4444;
}

.main-content {
    margin-left: var(--sw);
    flex: 1;
    min-width: 0;
    display: flex;
    flex-direction: column;
    min-height: 100vh;
}

.topbar {
    background: var(--surface);
    border-bottom: 1px solid var(--border);
    padding: 0 28px;
    height: 60px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    position: sticky;
    top: 0;
    z-index: 100;
}

.page-title {
    font-size: 16px;
    font-weight: 700;
}

.topbar-right {
    display: flex;
    align-items: center;
    gap: 14px;
}

.admin-badge {
    display: flex;
    align-items: center;
    gap: 8px;
    background: var(--primary-light);
    border-radius: 20px;
    padding: 5px 12px 5px 6px;
    font-size: 12.5px;
    font-weight: 600;
    color: var(--primary-h);
}

.admin-badge .ava {
    width: 26px;
    height: 26px;
    background: var(--primary);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #fff;
    font-size: 12px;
    font-weight: 700;
}

.page-body {
    padding: 28px;
    flex: 1;
}

.card {
    border: 1px solid var(--border);
    border-radius: 14px;
    box-shadow: 0 1px 4px rgba(0,0,0,.05);
}

.card-header-custom {
    padding: 18px 20px 14px;
    border-bottom: 1px solid var(--border);
    display: flex;
    align-items: center;
    justify-content: space-between;
}

.card-header-custom .ch-title {
    font-size: 14.5px;
    font-weight: 700;
}

.stat-card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 14px;
    padding: 20px;
    display: flex;
    justify-content: space-between;
    box-shadow: 0 1px 4px rgba(0,0,0,.04);
}

.stat-card .stat-icon {
    width: 44px;
    height: 44px;
    border-radius: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 20px;
}

.stat-label {
    font-size: 12px;
    color: var(--muted);
}

.stat-value {
    font-size: 26px;
    font-weight: 800;
    font-family: 'Space Mono', monospace;
}

.stat-sub {
    font-size: 11.5px;
    color: var(--muted);
}

.table-wrap {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 14px;
    overflow: hidden;
}

.table {
    margin: 0;
    font-size: 13.5px;
}

.table thead th {
    background: #f8fafc;
    font-weight: 800;
    font-size: 12px;
    text-transform: uppercase;
    letter-spacing: .5px;
}

.table tbody td {
    padding: 12px 16px;
    border-bottom: 1px solid #f1f5f9;
    vertical-align: middle;
}

.table tbody tr:hover td {
    background: #f8fffe;
}

.form-control,
.form-select {
    border: 1px solid var(--border);
    border-radius: 9px;
    font-size: 13.5px;
    padding: 9px 13px;
}

.form-control:focus,
.form-select:focus {
    border-color: var(--primary);
    box-shadow: 0 0 0 3px rgba(22,163,74,.12);
}

.form-label {
    font-size: 13px;
    font-weight: 600;
}

.btn {
    border-radius: 9px;
    font-size: 13px;
    font-weight: 600;
    padding: 8px 16px;
}

.btn-primary {
    background: var(--primary);
    border-color: var(--primary);
}

.btn-primary:hover {
    background: var(--primary-h);
    border-color: var(--primary-h);
}

.btn-sm {
    padding: 5px 11px;
    font-size: 12px;
}

.alert {
    border-radius: 10px;
    font-size: 13.5px;
    border: none;
}

.search-box {
    position: relative;
}

.search-box i {
    position: absolute;
    left: 11px;
    top: 50%;
    transform: translateY(-50%);
    color: var(--muted);
    font-size: 14px;
}

.search-box input {
    padding-left: 34px;
}

.sidebar-toggle {
    display: none;
    background: none;
    border: none;
    font-size: 20px;
}

.sidebar-overlay {
    display: none;
    position: fixed;
    inset: 0;
    background: rgba(0,0,0,.4);
    z-index: 999;
}

.sidebar-overlay.show {
    display: block;
}

@media(max-width:768px) {
    .sidebar {
        transform: translateX(-100%);
    }

    .sidebar.open {
        transform: translateX(0);
    }

    .main-content {
        margin-left: 0;
    }

    .sidebar-toggle {
        display: block;
    }

    .page-body {
        padding: 16px;
    }
}
</style>
</head>

<body>

<div class="sidebar-overlay" id="sidebarOverlay" onclick="closeSidebar()"></div>

<aside class="sidebar" id="sidebar">
    <div class="sidebar-brand">
        <div class="brand-icon">
            <i class="bi bi-box-seam-fill"></i>
        </div>
        <div>
            <div class="brand-name">Easy Inventory</div>
        </div>
    </div>

    <nav>
        <div class="sidebar-section-label">Utama</div>
        <?php foreach ($nav_main as $item) navLink($item, $active_menu); ?>

        <div class="sidebar-section-label">Manajemen</div>
        <?php foreach ($nav_manajemen as $item) navLink($item, $active_menu); ?>

        <div class="sidebar-section-label">Monitoring</div>
        <?php foreach ($nav_monitoring as $item) navLink($item, $active_menu, $expired_badge); ?>
    </nav>

    <div class="sidebar-footer">
        <a href="logout.php">
            <i class="bi bi-box-arrow-left"></i> Logout
        </a>
    </div>
</aside>

<div class="main-content">
    <div class="topbar">
        <div style="display:flex;align-items:center;gap:12px;">
            <button class="sidebar-toggle" onclick="toggleSidebar()">
                <i class="bi bi-list"></i>
            </button>
            <span class="page-title"><?= htmlspecialchars($page_title) ?></span>
        </div>

        <div class="topbar-right">
            <div class="admin-badge">
                <div class="ava">
                    <?= strtoupper(substr($admin_name, 0, 1)) ?>
                </div>
                <?= htmlspecialchars($admin_name) ?>
            </div>
        </div>
    </div>

    <div class="page-body">
        <?= $content ?? '' ?>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>

<script>
function toggleSidebar(){
    document.getElementById('sidebar').classList.toggle('open');
    document.getElementById('sidebarOverlay').classList.toggle('show');
}

function closeSidebar(){
    document.getElementById('sidebar').classList.remove('open');
    document.getElementById('sidebarOverlay').classList.remove('show');
}
</script>

</body>
</html>