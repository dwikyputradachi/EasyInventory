<?php
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

include 'koneksi.php';

if (isset($_SESSION['admin']) && ($_SESSION['admin']['role'] ?? '') === 'admin') {
    header("Location: index.php");
    exit();
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email = trim($_POST['email'] ?? '');
    $password = trim($_POST['password'] ?? '');

    $stmt = $connect->prepare("
        SELECT id_user, name, email, password, role
        FROM users
        WHERE email = ?
        AND role = 'admin'
        LIMIT 1
    ");

    if ($stmt) {
        $stmt->bind_param("s", $email);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result && $result->num_rows > 0) {
            $admin = $result->fetch_assoc();

            $storedPassword = $admin['password'] ?? '';
            $isValidPassword = password_verify($password, $storedPassword) || $password === $storedPassword;

            if ($isValidPassword) {
                $_SESSION['admin'] = [
                    'id_user' => $admin['id_user'],
                    'name'    => $admin['name'],
                    'email'   => $admin['email'],
                    'role'    => $admin['role']
                ];

                header("Location: index.php");
                exit();
            } else {
                $error = "Password salah!";
            }
        } else {
            $error = "Akun admin tidak ditemukan!";
        }
    } else {
        $error = "Query login gagal: " . $connect->error;
    }
}
?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login Admin — Easy Inventory</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&display=swap" rel="stylesheet">
    <style>
        body {
            min-height: 100vh;
            background: #f0fdf4;
            font-family: 'Plus Jakarta Sans', sans-serif;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .login-card {
            width: 100%;
            max-width: 390px;
            background: #fff;
            border: 1px solid #dcfce7;
            border-radius: 18px;
            box-shadow: 0 10px 35px rgba(22, 163, 74, .12);
            padding: 28px;
        }

        .brand-icon {
            width: 48px;
            height: 48px;
            border-radius: 14px;
            background: #16a34a;
            color: #fff;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 800;
            margin: 0 auto 12px;
        }

        .btn-success {
            background: #16a34a;
            border-color: #16a34a;
            font-weight: 700;
            border-radius: 10px;
            padding: 10px;
        }

        .form-control {
            border-radius: 10px;
            padding: 10px 12px;
        }

        .form-control:focus {
            border-color: #16a34a;
            box-shadow: 0 0 0 3px rgba(22,163,74,.12);
        }
    </style>
</head>
<body>

<div class="login-card">
    <div class="brand-icon">EI</div>
    <h4 class="text-center fw-bold mb-1">Easy Inventory</h4>
    <p class="text-center text-muted mb-4" style="font-size:13px;">Admin Web Login</p>

    <?php if (!empty($error)): ?>
        <div class="alert alert-danger py-2" style="font-size:13px;">
            <?= htmlspecialchars($error) ?>
        </div>
    <?php endif; ?>

    <form method="POST">
        <div class="mb-3">
            <label class="form-label fw-semibold">Email Admin</label>
            <input type="email" name="email" class="form-control" placeholder="admin@email.com" required>
        </div>

        <div class="mb-3">
            <label class="form-label fw-semibold">Password</label>
            <input type="password" name="password" class="form-control" placeholder="Masukkan password" required>
        </div>

        <button type="submit" class="btn btn-success w-100">Login</button>
    </form>
</div>

</body>
</html>
