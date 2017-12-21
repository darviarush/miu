# use IPC::Open3;

# use POSIX ":sys_wait_h";

# my($wtr, $rdr, $err);
# use Symbol 'gensym'; $err = gensym;
# $pid = open3($wtr, $rdr, $err,
		# '/cygdrive/c/sbin/nodejs/node.exe', '.miu/10-miu.t.js');
		
		
		
# waitpid( $pid, 0 );
# print "done\n";

use IPC::Open3::Simple;

my @out;
my @err;

my $ipc = IPC::Open3::Simple->new(
	out => sub { print "out: $_[0]\n"; },
	err => sub { print "err: $_[0]\n"; },
);

$ipc->run('/cygdrive/c/sbin/nodejs/node.exe .miu/10-miu.t.js');