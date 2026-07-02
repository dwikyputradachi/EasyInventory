<?php

function createReceiptItem(
    $conn,
    $id_user,
    $id_item,
    $id_category,
    $name,
    $quantity,
    $unit_price,
    $receipt_name = 'Manual Purchase'
) {
    $id_user = (int)$id_user;
    $id_item = (int)$id_item;
    $id_category = $id_category !== null ? (int)$id_category : null;
    $quantity = (int)$quantity;
    $unit_price = (float)$unit_price;
    $total_price = $quantity * $unit_price;

    if ($id_user <= 0 || $id_item <= 0 || $quantity <= 0 || $unit_price <= 0 || trim($name) === '') {
        return [
            "success" => false,
            "message" => "Data receipt tidak valid"
        ];
    }

    $receipt = $conn->prepare("
        INSERT INTO receipt (id_user, name)
        VALUES (?, ?)
    ");

    if (!$receipt) {
        return [
            "success" => false,
            "message" => "Prepare receipt failed",
            "error" => $conn->error
        ];
    }

    $receipt->bind_param("is", $id_user, $receipt_name);

    if (!$receipt->execute()) {
        return [
            "success" => false,
            "message" => "Receipt gagal disimpan",
            "error" => $receipt->error
        ];
    }

    $id_receipt = $conn->insert_id;

    $item = $conn->prepare("
        INSERT INTO receipt_item
        (id_receipt, id_item, id_category, name, quantity, price)
        VALUES (?, ?, ?, ?, ?, ?)
    ");

    if (!$item) {
        return [
            "success" => false,
            "message" => "Prepare receipt item failed",
            "error" => $conn->error
        ];
    }

    $item->bind_param(
        "iiisid",
        $id_receipt,
        $id_item,
        $id_category,
        $name,
        $quantity,
        $total_price
    );

    if (!$item->execute()) {
        return [
            "success" => false,
            "message" => "Receipt item gagal disimpan",
            "error" => $item->error
        ];
    }

    return [
        "success" => true,
        "id_receipt" => $id_receipt,
        "total_price" => $total_price
    ];
}