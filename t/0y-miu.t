#!/usr/bin/env perl
# сгенерировано miu

use utf8;
use open qw/:std :utf8/;

BEGIN {
	select(STDERR);	$| = 1;
	select(STDOUT); $| = 1; # default
	close STDERR; open(STDERR, ">&STDOUT");
}

use Test::More tests => 3;
::is( scalar(1), "1", "1 # 1" );

print "== Переход" . "\n";
::is( scalar(1), "1", "1 # 1" );

print "== Закончили" . "\n";
::is( scalar(6), "6", "6 # 6" );