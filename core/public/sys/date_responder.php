<?php 
list($usec, $sec) = explode(" ", microtime());
printf("%d%03d\n", $sec, $usec * 1000);
printf("%d\n", date_offset_get(date_create()));
printf("%s\n", strftime("%Z\n%Y-%m-%d\n%T"));
?>
