<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type");

include("dbconnect.php");

// Default limit is 50 records if not specified
$limit = isset($_GET['limit']) ? intval($_GET['limit']) : 50;

$sql = "SELECT * FROM `baby_monitor` ORDER BY `id` DESC LIMIT $limit";
$result = mysqli_query($conn, $sql);

$data = array();

while ($row = mysqli_fetch_assoc($result)) {
    $data[] = array(
        'id' => $row['id'],
        'temp' => $row['temp'],
        'hum' => $row['hum'],
        'dist' => $row['dist'],
        'relay' => $row['relay'],
        'motion' => $row['motion'],
        'vibrate' => $row['vibrate'],
        'status' => $row['status'],
        'safety' => $row['safety'],
        'mode' => $row['mode'],
        'timestamp' => date("c", strtotime($row['timestamp'])),
        
    );
}

// Reverse to show from oldest to newest
$data = array_reverse($data);

echo json_encode($data);
?>
