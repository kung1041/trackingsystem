<?php
header("content-type:text/javascript;charset=utf-8");
error_reporting(0);
error_reporting(E_ERROR | E_PARSE);
$link = mysqli_connect('localhost', 'root', '', "ProjectFlutter");

if (!$link) {
    echo "Error: Unable to connect to MySQL." . PHP_EOL;
    echo "Debugging errno: " . mysqli_connect_errno() . PHP_EOL;
    echo "Debugging error: " . mysqli_connect_error() . PHP_EOL;
    
    exit;
}else {

	if (isset($_GET)) {
	if ($_GET['isAdd'] == 'true') {
			
		$Voice_id = $_GET['Voice_id'];		
									
		$sql = "DELETE FROM trackingsystem WHERE Voice_id = '$Voice_id'";

		$result = mysqli_query($link, $sql);

		if ($result) {
			echo "True";
		} else {
			echo "False";
		}

	} else echo "Welcome delete kung";
   
}
	
}
	mysqli_close($link);
?>