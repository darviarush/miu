package Miu::Essential;
# необходимые функции для разработки

use common::sense;
use Term::ANSIColor qw/colored color/;
use File::Find qw//;

# импортирует в вызывавший модуль функции
my %EXPORT = (map {$_=>1} qw/TODO msg msg1 colored color executor mkpath input output inputini find minusroot readypath clearpath/);
sub import {
	my $self = shift;
	
	my $caller = caller;
	
	require warnings;
	
	my $once = $warnings::Offsets{'once'};
	
	my $save = vec(${^WARNING_BITS}, $once, 1);
	
	for my $name (@_? @_: keys %EXPORT) {
		my $v = $EXPORT{$name};
		die "нет такого имени `$name`" if !defined $v;
		
		if($v == 0) {
			*{"${caller}::$v"} = \${$v};
		}
		else {
			*{"${caller}::$name"} = \&$name;
		}
	
	}
	
	vec(${^WARNING_BITS}, $once, 1) = $save;
	
	#${^WARNING_BITS} ^= ${^WARNING_BITS} ^ ;
	vec(${^WARNING_BITS}, $warnings::Offsets{'recursion'}, 1) = 1;
	
	$self;
}


sub TODO () {
	my ($pkg, $file, $line, $sub) = caller(1);
	print STDERR "не используется $sub\n";
	return
}

# сообщение на консоль
sub msg {
	use Data::Dumper;
	local ($_, $`, $', $1);
	my $color;
	print STDERR join ", ", map { ref $_ ne ""? Dumper($_): /^:(\w+(?:\s+\w+)*)$/? color($color = $1): $_} @_;
	print STDERR color("reset") if $color;
	print STDERR "\n";
	return $_[0];
}


# дополняет вывод строкой, чтобы было видно лучше
sub msg1 {
	print STDERR colored(["yellow on_red"], "=============") . " ";
	goto &msg;
}

# утилита для обнаружения полного пути к исполняемому файлу
sub executor {
	my ($executor) = @_;
	local ($_, $!);
	my $x;
	
	my $PATH = $ENV{'PATH'};
	my @PATH = split /[:;]/, $PATH;
	
	(-x($x = "$_/$executor") or -f($x = "$_/$executor.exe")) and return $x for @PATH;
	
	die "не удалось обнаружить $executor в PATH=$PATH";
}

# поиск файлов
sub find (&@) {
	my ($sub, @paths) = @_;
	
	my @path;
	File::Find::find({
		no_chdir => 1,
		wanted => sub {
			push @path, $File::Find::name;
		}
	}, @paths);
	
	map { $sub->() } sort @path;
}

# создаёт пути
sub mkpath ($;$) {
	my ($path, $mod) = @_;
	local $!;
	$mod //= 0744;
	mkdir $`, $mod while $path =~ m!/!g;
	$path
}

# очищает директорию, но саму не удаляет
sub clearpath ($) {
	my ($path) = @_;
	
	local $!;
	
	#msg1 "clearpath", $path;
	
	my @dir;
	find {
		if(-d) { push @dir, $_ if $path ne $_; } else { unlink; }
	} $path;
	
	rmdir for @dir;
	
	$path
}

# очищает или создаёт каталог
sub readypath ($;$) {
	my ($path, $mod) = @_;
	
	mkpath $path, $mod;
	clearpath $path;
	
	$path
}

# считывает файл
sub input (@) {
	my ($path, $err, $layer) = @_;
	$layer //= "utf8";
	open my $f, "<:$layer", $path or die $err? sprintf($err, $path, $!): "невозможно открыть файл `$path`: $!";
	read $f, my $data, -s $f;
	close $f;
	$data
}

# записывает в файл
sub output (@) {
	my ($path, $text, $err, $layer) = @_;
	$layer //= "utf8";
	open my $f, ">:$layer", $path or die $err? sprintf($err, $path, $!): "невозможно создать файл `$path`: $!";
	my $size = print $f ref $text? @$text: $text;
	close $f;
	$size
}

# считывает ini-файл и возвращает хэш с его параметрами
sub inputini ($) {
	my ($path) = @_;
	my $x = {};
	my $i = 1;
	for my $line ( split /\n/, input $path ) {
		next if $line =~ /^#|^\s*$/;
		msg "повреждён ini-файл $path на строке $i." if $line !~ /^\s*(.*?)\s*=\s*(.*?)\s*$/;
		$x->{$1} = $2;
	}
	continue {$i++}
	$x
}
	
# удаляет рутовую директорию из пути
sub minusroot ($$) {
	my ($root, $path) = @_;
	$root =~ s!/?$!/!;
	my $reroot = quotemeta $root;
	die "не могу вычесть `$root` из `$path`" if $path !~ s!^$reroot!!;
	$path
}

1;