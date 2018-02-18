package EssentialMiu;
# необходимые функции для разработки

use common::sense;
use Term::ANSIColor qw/colored color/;

# импортирует в вызывавший модуль функции
my %EXPORT = (map {$_=>1} qw/TODO msg msg1 colored color executor mkpath input output/);
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
	
	-x($x = "$_/$executor") and return $x for @PATH;
	
	die "не удалось обнаружить $executor в PATH=$PATH";
}

# создаёт пути
sub mkpath ($) {
	my ($path) = @_;
	local $_;
	mkdir $` while $path =~ m!/!g;
	undef $!;
	$path
}

# считывает файл
sub input ($) {
	my ($path) = @_;
	open my $f, "<:utf8", $path or die "невозможно открыть файл `$path`: $!";
	read $f, my $data, -s $f;
	close $f;
	$data
}

# записывает в файл
sub output ($@) {
	my $path = shift;
	open my $f, ">:utf8", $path or die "невозможно создать файл `$path`: $!";
	my $size = print $f @_;
	close $f;
	$size
}

1;