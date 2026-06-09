<?php

include_once '../config/response.php';
include_once '../config/database.php';

/** @var mysqli $conn */

$sql = "UPDATE notification SET is_read = 1 WHERE is_read = 0";

if ($conn->query($sql)) {
    echo json_encode([
        "success" => true,
        "message" => "All notifications deleted from list"
    ]);
} else {
    echo json_encode([
        "success" => false,
        "message" => "Failed to update notifications"
    ]);
}