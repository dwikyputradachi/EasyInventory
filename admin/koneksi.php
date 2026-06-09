<?php
$connect = new mysqli("localhost", "root", "", "inventory_app");
if ($connect->connect_error) {
    die("Connection Failed: " . $connect->connect_error);
}
$connect->set_charset("utf8mb4");
?>