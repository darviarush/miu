#!/usr/bin/env perl
# сгенерировано miu

use utf8;
use open qw/:std :utf8/;

BEGIN {
	select(STDERR);	$| = 1;
	select(STDOUT); $| = 1; # default
	close STDERR; open(STDERR, ">&STDOUT");
}

use Test::More tests => 33;

my $_f;
print "= miu - система одновременного кодирования, документирования и тестирования" . "\n";
print "== Что такое miu" . "\n";
print "== Быстрый старт" . "\n";
::is( scalar(my $abs = 16), "16", "my \$abs = 16;	# 16" );

::is( scalar(`miu 0x -cC`), "0x-miu.miu.pl ... ok\n", "`miu 0x -cC` # 0x-miu.miu.pl ... ok\n" );

::is( scalar(1+5), "6", "1+5 # 6" );
::is_deeply( scalar(1+5), scalar(1+5), "1+5 ## 1+5" );
::is( scalar(" 26\n"), " 26\n", "\" 26\n\" #  26\n" );
::is_deeply( scalar(bless {a=>2}, "Class"), scalar(bless {a=>2}, "Class"), "bless {a=>2}, \"Class\" ## bless {a=>2}, \"Class\"" );

# ну а это просто комментарий, так как перед ним ничего нет!

::cmp_ok( scalar(2**3), '<', "10", "2**3 #< 10" );
::cmp_ok( scalar(8), '!=', "3", "8 #!= 3" );
::cmp_ok( scalar("8"), '==', "8", "\"8\" #== 8" );
::cmp_ok( scalar("meat"), 'ne', "eat", "\"meat\" #ne eat" );
::cmp_ok( scalar("abc"), 'lt', scalar("eat"), "\"abc\" ##lt \"eat\"" );
::like( scalar("test"), qr{es.$}, "\"test\" #~ es.\$" );
::unlike( scalar({}), qr{(?i)^array}, "{} #!~ (?i)^array" );
::is( substr(scalar(123456), 0, length($_ret = "123")), $_ret, "123456 #startswith 123" );
::is( substr(scalar(123456), -length($_ret = "456")), $_ret, "123456 #endswith 456" );

eval { die "myexception" }; ::is( substr(scalar($@), 0, length($_ret = "myexception")), $_ret, "die \"myexception\" #\@ startswith myexception" );
eval { die "myexception" }; ::unlike( scalar($@), scalar(qr/чего\?/), "die \"myexception\" ##\@ !~ qr/чего\\?/" );
eval { die "myexception" }; ::unlike( scalar($@), qr{чего\?}, "die \"myexception\" #\@ !~ чего\\?" );

{ local *STDOUT; open STDOUT, '>', \$_f; binmode STDOUT; print "123\n"; close STDOUT }; ::is( scalar($_f), "123\n", "print \"123\n\" #>> 123\n" );

{ local *STDERR; open STDERR, '>', \$_f; binmode STDOUT; print STDERR " +26\t\r\e\v"; close STDERR; }; ::is( scalar($_f), " +26\t\r\e\v", "print STDERR \" +26\t\r\e\v\" #&>  +26\t\r\e\v" );

open $f, ">", "/"; ::is_deeply( scalar($!), scalar("Is a directory"), "open \$f, \">\", \"/\"; ##! \"Is a directory\"" );

eval {
	die "abc";
};
::is( substr(scalar($@), 0, length($_ret = "abc")), $_ret, "\$\@;			#startswith abc" );

sub for_io_test {

    print "12";
    print "3\n";

}

{ local *STDOUT; open STDOUT, '>', \$_f; binmode STDOUT; for_io_test(); close STDOUT }; ::is( scalar($_f), "123\n", "for_io_test(); #>> 123\n" );

print "=== Тестируем javascript" . "\n";
print "== Программный код" . "\n";
use A::A;
{ local *STDOUT; open STDOUT, '>', \$_f; binmode STDOUT; &A::A::A; close STDOUT }; ::is( scalar($_f), "A", "&A::A::A; #>> A" );
{ local *STDOUT; open STDOUT, '>', \$_f; binmode STDOUT; &A::A::N; close STDOUT }; ::is( scalar($_f), "N", "&A::A::N; #>> N" );


{ local *STDOUT; open STDOUT, '>', \$_f; binmode STDOUT; require "./.miu/test.pl"; close STDOUT }; ::is( scalar($_f), "AN", "require \"./.miu/test.pl\"; #>> AN" );
::is( scalar(`perl .miu/test.pl`), "AN", "`perl .miu/test.pl` # AN" );

print "== Как выполнить тесты из раздела статьи" . "\n";
print "=== Маски файлов и разделов" . "\n";
::is( scalar(`miu 0x метки Второй -cC`), "0x-miu.miu.pl .. ok\n", "`miu 0x метки Второй -cC` # 0x-miu.miu.pl .. ok\n" );

::is( scalar(`miu 0x:0y метки какие -cC`), "0x-miu.miu.pl . ok\n0y-miu.miu.pl ... ok\n", "`miu 0x:0y метки какие -cC` # 0x-miu.miu.pl . ok\n0y-miu.miu.pl ... ok\n" );

::is( scalar(`miu 0x метки\$ ^Второй -cC`), "0x-miu.miu.pl . ok\n", "`miu 0x метки\\\$ ^Второй -cC` # 0x-miu.miu.pl . ok\n" );

::is( scalar(`miu 0x етк торо -cC`), "0x-miu.miu.pl .. ok\n", "`miu 0x етк торо -cC` # 0x-miu.miu.pl .. ok\n" );

print "=== Инициализатор" . "\n";
# инициализация тестов

print "== Конфигурационный файл" . "\n";
print "== Какие файлы создаёт miu" . "\n";
print `pwd`;
::is( scalar(`cd ..; miu -cC miu/0x -o miu/.miu`), "miu/0x-miu.miu.pl ... ok\n", "`cd ..; miu -cC miu/0x -o miu/.miu` # miu/0x-miu.miu.pl ... ok\n" );

::like( scalar(`miu -cC -l 0x`), qr{\.*}, "`miu -cC -l 0x` #~ \\.*" );

print "== Установка" . "\n";
print "== Как конвертировать markdown в html" . "\n";
print "=== Как конвертировать markdown в bbcode" . "\n";
print "== Откуда название **miu**?" . "\n";
print "== TODO или куда miu будет развиваться" . "\n";