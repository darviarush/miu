#!/usr/bin/env perl
# сгенерировано miu

use utf8;
use open qw/:std :utf8/;

BEGIN {
	select(STDERR);	$| = 1;
	select(STDOUT); $| = 1; # default
	close STDERR; open(STDERR, ">&STDOUT");
}

use Test::More tests => 2;
print "==== Тестируем количество \"=\"" . "\n";
::is( scalar(6), "6", "6 # 6" );

print "=== Второй раздел" . "\n";
::is( scalar(7), "7", "7 # 7" );