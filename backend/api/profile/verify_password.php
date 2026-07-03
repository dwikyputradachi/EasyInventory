    <?php
    require_once __DIR__ . '/../config/response.php';
    require_once __DIR__ . '/../config/database.php';
    require_once __DIR__ . '/../config/auth_middleware.php';

    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        error('Method not allowed', 405);
    }

    $user = authenticate();

    $data = json_decode(file_get_contents('php://input'), true);

    if (!isset($data['password']) || trim($data['password']) === '') {
        error('Password wajib diisi', 400);
    }

    $password = $data['password'];

    $db = getDB();

    $stmt = $db->prepare('SELECT password FROM users WHERE id_user = ?');
    $stmt->bind_param('i', $user['id_user']);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows == 0) {
        error('User tidak ditemukan', 404);
    }

    $row = $result->fetch_assoc();

    if (!password_verify($password, $row['password'])) {
        error('Password salah', 401);
    }

    $db->close();

    success([], 'Password valid');