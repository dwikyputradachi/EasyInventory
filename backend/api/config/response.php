<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Authorization, Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

function success($data = null, $message = 'OK') {
    echo json_encode(['status' => 'success', 'message' => $message, 'data' => $data]);
    exit;
}

function error($message = 'Error', $code = 400) {
    http_response_code($code);
    echo json_encode(['status' => 'error', 'message' => $message]);
    exit;
}

function bodyJson() {
    return json_decode(file_get_contents('php://input'), true) ?? [];
}