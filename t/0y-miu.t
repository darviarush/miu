#!/usr/bin/env perl
# сгенерировано miu

BEGIN {
	select(STDERR);	$| = 1;
	select(STDOUT); $| = 1; # default
	
	open(our $__Miu__STDERR, ">&STDERR") or die $!;
	close STDERR or die $!;
	open(STDERR, ">&STDOUT") or die $!;
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
::is( scalar(1), "1", "1 # 1" );

print "== Переход" . "\n";
::is( scalar(1), "1", "1 # 1" );

print "== Закончили" . "\n";
::is( scalar(6), "6", "6 # 6" );