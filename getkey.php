<?php


// Check if function exists (php5.4+ includes this method)
if(!function_exists("hex2bin")){
        function hex2bin($h)
        {
               if (!is_string($h))
                       return null;
               $r = '';
               for ($a=0;$a<strlen($h);$a+=2)
              {
                       $r .= chr(hexdec($h{$a}.$h{($a+1)}));
              }
              return $r;
       }
}

if ($_GET['proxy_sessionid']==='p1234') $isValid = true;
else $isValid = false;

if (! $isValid)
{
	header('HTTP/1.0 403 Forbidden');
}
else
{
	header('Content-Type: binary/octet-stream');
	header('Pragma: no-cache');


	echo hex2bin('6B4FD65C3726B7969E1A09D897E57BE0');

	exit(); // this is needed to ensure cr/lf is not added to output
}


?>

