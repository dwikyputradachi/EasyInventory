<?php

function syncItemNotifications($conn, $item)
{
    $id_item = (int)$item['id_item'];
    $name = $item['name'];
    $stok = (int)$item['stok'];
    $expired_date = $item['expired_date'];

    // Hapus notification aktif lama untuk item ini
    $delete = $conn->prepare("
        DELETE FROM notification 
        WHERE id_item = ? 
        AND is_read = 0
        AND type IN ('low_stock', 'near_expired', 'expired')
    ");
    $delete->bind_param("i", $id_item);
    $delete->execute();

    // Low stock
    if ($stok <= 5) {
        $type = "low_stock";
        $message = "Current stock: " . $stok;

        $insert = $conn->prepare("
            INSERT INTO notification (id_item, title, message, type, is_read)
            VALUES (?, ?, ?, ?, 0)
        ");
        $insert->bind_param("isss", $id_item, $name, $message, $type);
        $insert->execute();
    }

    // Expired / Near Expired
    if (!empty($expired_date)) {
        $today = new DateTime(date("Y-m-d"));
        $expiredDate = new DateTime($expired_date);
        $daysLeft = (int)$today->diff($expiredDate)->format("%r%a");

        if ($daysLeft <= 0) {
            $type = "expired";
            $message = "Expired on " . $expiredDate->format("d M Y");
        } elseif ($daysLeft <= 7) {
            $type = "near_expired";
            $message = "Expires in " . $daysLeft . " day(s) (" . $expiredDate->format("d M Y") . ")";
        } else {
            $type = null;
            $message = null;
        }

        if ($type !== null) {
            $insert = $conn->prepare("
                INSERT INTO notification (id_item, title, message, type, is_read)
                VALUES (?, ?, ?, ?, 0)
            ");
            $insert->bind_param("isss", $id_item, $name, $message, $type);
            $insert->execute();
        }
    }
}