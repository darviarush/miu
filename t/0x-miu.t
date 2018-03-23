#!/usr/bin/env perl
# сгенерировано miu

BEGIN {
	select(STDERR);	$| = 1;
	select(STDOUT); $| = 1; # default
	
	open(STDERR, ">&STDOUT");
}

use utf8;

use open ":std", ":encoding(utf8)";
use Test::More tests => 3;

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
print "== Для статьи про mio" . "\n";
is( scalar(1), "1", "1 # 1" );

print "=== Метки 1" . "\n";
print "==== Тестируем количество \"=\"" . "\n";
is( scalar(6), "6", "6 # 6" );

print "=== Второй раздел" . "\n";
is( scalar(7), "7", "7 # 7" );