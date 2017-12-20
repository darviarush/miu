use IPC::Open3;

use POSIX ":sys_wait_h";

my($wtr, $rdr, $err);
use Symbol 'gensym'; $err = gensym;
$pid = open3($wtr, $rdr, $err,
		'/cygdrive/c/sbin/nodejs/node.exe', '.miu/10-miu.t.js');
		
		
		
while(waitpid( $pid, WNOHANG ) > 0) {
	
}

print "done\n";