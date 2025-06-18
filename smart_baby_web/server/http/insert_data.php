<?php
error_reporting(0);
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type");

include_once("dbconnect.php");

$temp = $_GET['temp'];
$hum = $_GET['hum'];
$dist = $_GET['dist'];
$relay = $_GET['relay'];
$motion = $_GET['motion'];
$vibrate = $_GET['vibrate'];
$status = $_GET['status'];
$safety = $_GET['safety'];
$mode = $_GET['mode'];

$sqlinsert = "INSERT INTO `baby_monitor`(`temp`, `hum`, `dist`, `relay`, `motion`, `vibrate`, `status`, `safety`, `mode`)
        VALUES ('$temp', '$hum', '$dist', '$relay', '$motion', '$vibrate', '$status', '$safety',  '$mode')";

if ($conn->query($sqlinsert) === TRUE) {
    echo "Success";
} else {
    echo "failed";
}

$conn->close();
?>
