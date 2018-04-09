#!/usr/bin/env perl
# сгенерировано miu

BEGIN {
	select(STDERR);	$| = 1;
	select(STDOUT); $| = 1; # default
	
	open(STDERR, ">&STDOUT");
}

use utf8;

use open ":std", ":encoding(utf8)";
use Test::More tests => 2;

my ($_f, $_ret);

sub ___std {
my $fh = shift;
open $_f, ">&", $fh; close $fh; open $fh, ">", ".miu/miu-tmp-fh";
}

sub ___res {
my $fh = shift;
close $fh;
open $fh, ">&", $_f;
}

sub ___get {
open my $f, ".miu/miu-tmp-fh";
read $f, my $buf, -s $f;
close $f;
$buf
}
print `pwd`;
is( scalar(`cd ..; miu -c miu/0x -o miu/.miu`), "miu/0x-miu.miu.pl ... ok\n", "`cd ..; miu -c miu/0x -o miu/.miu` # miu/0x-miu.miu.pl ... ok\\n" );

like( scalar(`miu -c -l 0x`), qr{\.*}, "`miu -c -l 0x` #~ \.*" );

print "== Установка" . "\n";