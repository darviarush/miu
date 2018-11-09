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
use Test::More tests => 33;

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
print "= miu - система одновременного кодирования, документирования и тестирования" . "\n";
print "== Что такое miu" . "\n";
print "== Быстрый старт" . "\n";
is( scalar(my $abs = 16), "16", "my \$abs = 16;	# 16" );

is( scalar(`miu 0x -c`), "0x-miu.miu.pl ... ok\n", "`miu 0x -c` # 0x-miu.miu.pl ... ok\\n" );

is( scalar(1+5), "6", "1+5 # 6" );
is_deeply( scalar(1+5), scalar(1+5), "1+5 ## 1+5" );
is( scalar(" 26\n"), " 26\n", "\" 26\\n\" #  26\\n" );
is_deeply( scalar(bless {a=>2}, "Class"), scalar(bless {a=>2}, "Class"), "bless {a=>2}, \"Class\" ## bless {a=>2}, \"Class\"" );

# ну а это просто комментарий, так как перед ним ничего нет!

cmp_ok( scalar(2**3), '<', "10", "2**3 #< 10" );
cmp_ok( scalar(8), '!=', "3", "8 #!= 3" );
cmp_ok( scalar("8"), '==', "8", "\"8\" #== 8" );
cmp_ok( scalar("meat"), 'ne', "eat", "\"meat\" #ne eat" );
cmp_ok( scalar("abc"), 'lt', scalar("eat"), "\"abc\" ##lt \"eat\"" );
like( scalar("test"), qr{es.$}, "\"test\" #~ es.\$" );
unlike( scalar({}), qr{(?i)^array}, "{} #!~ (?i)^array" );
is( substr(scalar(123456), 0, length($_ret = "123")), $_ret, "123456 #startswith 123" );
is( substr(scalar(123456), -length($_ret = "456")), $_ret, "123456 #endswith 456" );

eval { die "myexception" }; is( substr(scalar($@), 0, length($_ret = "myexception")), $_ret, "die \"myexception\" #\@ startswith myexception" );
eval { die "myexception" }; unlike( scalar($@), scalar(qr/чего\?/), "die \"myexception\" ##\@ !~ qr/чего\?/" );
eval { die "myexception" }; unlike( scalar($@), qr{чего\?}, "die \"myexception\" #\@ !~ чего\?" );

___std(\*STDOUT); print "123\n"; ___res(\*STDOUT); is( scalar(___get()), "123\n", "print \"123\\n\" #>> 123\\n" );

___std(\*STDERR); print STDERR " +26\t\r\e\v"; ___res(\*STDERR); is( scalar(___get()), " +26\t\r\e\v", "print STDERR \" +26\\t\\r\e\v\" #&>  +26\\t\\r\e\v" );

open $f, "/"; is_deeply( scalar($!), scalar(""), "open \$f, \"/\"; ##! \"\"" );

eval {
	die "abc";
};
is( substr(scalar($@), 0, length($_ret = "abc")), $_ret, "\$\@;			#startswith abc" );

sub for_io_test {

    print "12";
    print "3\n";

}

___std(\*STDOUT); for_io_test(); ___res(\*STDOUT); is( scalar(___get()), "123\n", "for_io_test(); #>> 123\\n" );

print "=== Тестируем javascript" . "\n";
print "== Программный код" . "\n";
use A::A;
___std(\*STDOUT); &A::A::A; ___res(\*STDOUT); is( scalar(___get()), "A", "&A::A::A; #>> A" );
___std(\*STDOUT); &A::A::N; ___res(\*STDOUT); is( scalar(___get()), "N", "&A::A::N; #>> N" );


___std(\*STDOUT); require "./.miu/test.pl"; ___res(\*STDOUT); is( scalar(___get()), "AN", "require \"./.miu/test.pl\"; #>> AN" );
is( scalar(`perl .miu/test.pl`), "AN", "`perl .miu/test.pl` # AN" );


print "== Как выполнить тесты из раздела статьи" . "\n";
print "=== Маски файлов и разделов" . "\n";
is( scalar(`miu 0x метки Второй -c`), "0x-miu.miu.pl .. ok\n", "`miu 0x метки Второй -c` # 0x-miu.miu.pl .. ok\\n" );

is( scalar(`miu 0x:0y метки какие -c`), "0x-miu.miu.pl . ok\n0y-miu.miu.pl ... ok\n", "`miu 0x:0y метки какие -c` # 0x-miu.miu.pl . ok\\n0y-miu.miu.pl ... ok\\n" );

is( scalar(`miu 0x метки\$ ^Второй -c`), "0x-miu.miu.pl . ok\n", "`miu 0x метки\\$ ^Второй -c` # 0x-miu.miu.pl . ok\\n" );

is( scalar(`miu 0x етк торо -c`), "0x-miu.miu.pl .. ok\n", "`miu 0x етк торо -c` # 0x-miu.miu.pl .. ok\\n" );

print "=== Инициализатор" . "\n";
# инициализация тестов

print "== Конфигурационный файл" . "\n";

print "== Какие файлы создаёт miu" . "\n";
print `pwd`;
is( scalar(`cd ..; miu -c miu/0x -o miu/.miu`), "miu/0x-miu.miu.pl ... ok\n", "`cd ..; miu -c miu/0x -o miu/.miu` # miu/0x-miu.miu.pl ... ok\\n" );

like( scalar(`miu -c -l 0x`), qr{\.*}, "`miu -c -l 0x` #~ \.*" );

print "== Установка" . "\n";
print "== Как конвертировать markdown в html" . "\n";
print "=== Как конвертировать markdown в bbcode" . "\n";
print "== Откуда название **miu**?" . "\n";
print "== TODO или куда miu будет развиваться" . "\n";