<?php

function normalizeShoppingText($text) {
    $text = strtolower(trim($text));
    $text = preg_replace('/[^a-z0-9\s]/', ' ', $text);
    $text = preg_replace('/\s+/', ' ', $text);
    return trim($text);
}

function getGenericShoppingName($conn, $productName) {
    $input = normalizeShoppingText($productName);

    if ($input === '') {
        return '';
    }

    $stmt = $conn->prepare("
        SELECT generic_name, alias_name
        FROM product_alias
        ORDER BY LENGTH(alias_name) DESC
    ");

    if (!$stmt) {
        return $input;
    }

    $stmt->execute();
    $result = $stmt->get_result();

    while ($row = $result->fetch_assoc()) {
        $alias = normalizeShoppingText($row['alias_name']);
        $generic = normalizeShoppingText($row['generic_name']);

        if ($alias !== '' && strpos($input, $alias) !== false) {
            return $generic;
        }

        if ($generic !== '' && strpos($input, $generic) !== false) {
            return $generic;
        }
    }

    return $input;
}

function saveUnmatchedProductAlias($conn, $id_user, $productName) {
    $id_user = (int)$id_user;
    $productName = trim($productName);

    if ($id_user <= 0 || $productName === '') {
        return [
            "saved" => false,
            "message" => "Invalid unmatched product data"
        ];
    }

    // Cegah duplicate pending untuk user dan produk yang sama
    $check = $conn->prepare("
        SELECT id_unmatched
        FROM unmatched_product_alias
        WHERE id_user = ?
        AND LOWER(product_name) = LOWER(?)
        AND status = 'pending'
        LIMIT 1
    ");

    if (!$check) {
        return [
            "saved" => false,
            "message" => "Prepare check unmatched failed",
            "error" => $conn->error
        ];
    }

    $check->bind_param("is", $id_user, $productName);
    $check->execute();
    $existing = $check->get_result()->fetch_assoc();

    if ($existing) {
        return [
            "saved" => false,
            "message" => "Unmatched product already exists",
            "id_unmatched" => $existing['id_unmatched']
        ];
    }

    $stmt = $conn->prepare("
        INSERT INTO unmatched_product_alias
        (id_user, product_name, status)
        VALUES (?, ?, 'pending')
    ");

    if (!$stmt) {
        return [
            "saved" => false,
            "message" => "Prepare insert unmatched failed",
            "error" => $conn->error
        ];
    }

    $stmt->bind_param("is", $id_user, $productName);

    if (!$stmt->execute()) {
        return [
            "saved" => false,
            "message" => "Insert unmatched failed",
            "error" => $stmt->error
        ];
    }

    return [
        "saved" => true,
        "message" => "Unmatched product saved",
        "id_unmatched" => $conn->insert_id
    ];
}

function markShoppingListIfMatched($conn, $id_user, $productName) {
    $id_user = (int)$id_user;
    $productName = trim($productName);
    $genericName = getGenericShoppingName($conn, $productName);

    if ($id_user <= 0 || $productName === '' || $genericName === '') {
        return [
            "matched" => false,
            "message" => "Invalid user or product name"
        ];
    }

    $stmt = $conn->prepare("
        SELECT 
            sli.id_shopping_item,
            sli.name_item,
            sl.id_shopping_list,
            sl.title
        FROM shopping_list_items sli
        JOIN shopping_lists sl 
            ON sli.id_shopping_list = sl.id_shopping_list
        WHERE sl.id_user = ?
        AND sl.status = 'active'
        AND sli.is_bought = 0
    ");

    if (!$stmt) {
        return [
            "matched" => false,
            "message" => "Prepare shopping list failed",
            "error" => $conn->error
        ];
    }

    $stmt->bind_param("i", $id_user);
    $stmt->execute();
    $result = $stmt->get_result();

    while ($row = $result->fetch_assoc()) {
        $listItemName = normalizeShoppingText($row['name_item']);
        $listGenericName = getGenericShoppingName($conn, $row['name_item']);

        $isMatch = false;

        if ($listItemName === $genericName) {
            $isMatch = true;
        }

        if ($listGenericName === $genericName) {
            $isMatch = true;
        }

        if ($isMatch) {
            $idShoppingItem = (int)$row['id_shopping_item'];

            $update = $conn->prepare("
                UPDATE shopping_list_items
                SET 
                    is_bought = 1,
                    matched_item_name = ?
                WHERE id_shopping_item = ?
            ");

            if (!$update) {
                return [
                    "matched" => false,
                    "message" => "Prepare update shopping item failed",
                    "error" => $conn->error
                ];
            }

            $update->bind_param("si", $productName, $idShoppingItem);

            if (!$update->execute()) {
                return [
                    "matched" => false,
                    "message" => "Update shopping item failed",
                    "error" => $update->error
                ];
            }

            return [
                "matched" => true,
                "generic_name" => $genericName,
                "shopping_item" => $row['name_item'],
                "matched_item_name" => $productName,
                "shopping_list_title" => $row['title']
            ];
        }
    }

    // Kalau tidak match ke shopping list aktif, simpan sebagai unmatched candidate
    $unmatchedResult = saveUnmatchedProductAlias($conn, $id_user, $productName);

    return [
        "matched" => false,
        "generic_name" => $genericName,
        "message" => "No active shopping list item matched",
        "unmatched" => $unmatchedResult
    ];
}