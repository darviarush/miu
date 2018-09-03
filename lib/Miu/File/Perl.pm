package Miu::File::Perl;
# драйвер тестов для языка perl

use base Miu::File::Test;

use common::sense;

use Miu::Essential;


# конструктор
sub new {
	my $cls = shift;
	(ref $cls || $cls)->SUPER::new(@_);
}


# возвращает название языка
sub name {
	"perl"
}


# возвращает расширение для файла теста которое будет указано после расширения теста: .t
sub test_ext {
	""
}

# возвращает путь к интерпретатору для tap-парсера
sub exec_param {
	my ($self, $miu) = @_;
	#my $run_dir = Cwd::abs_path($miu->{run_dir});
	#minusroot $run_dir, 
	return $^X, (map {('-I', $_)} @{ $miu->{include_dirs} }), $self->{path};
}

# возвращает символ комментария для регулярки
sub comment {
	"\\#"
}

# пытается распознать в строке ошибку и отмапить
sub mapiferror {
	my ($self, $s, $miu) = @_;
	
	my $path = $self->{regexp_path} //= do { my $p = quotemeta $self->{path}; qr!\bat $p line (\d+)! };
	my $lineno;
	if($s =~ $path) {
		my $lineno = $self->{map}[$1-1];
		$s =~ s!$path!$& (AKA $lineno IN $miu->{path})! if defined $lineno;
	}
	
	$s
}

# дополняем сохранение
sub before_save {
	my ($self) = @_;
	
	# дополняем тест
	my $out_dir = $self->{out_dir};
	$out_dir =~ s![\"]!\\$&!g;

	my $count_tests = $self->{count_tests};
	die "не указано количество тестов" if !defined $count_tests;
	
	$self->unshift_test('#!/usr/bin/env perl
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
use Test::More tests => ' . $count_tests . ';

my ($_f, $_ret);

sub ___std {
my $fh = shift;
open $_f, ">&", $fh; close $fh; open $fh, ">", "' . $out_dir . '/miu-tmp-fh";
}

sub ___res {
my $fh = shift;
close $fh;
open $fh, ">&", $_f;
}

sub ___get {
open my $f, "' . $out_dir . '/miu-tmp-fh";
read $f, my $buf, -s $f;
close $f;
$buf
}

');

}


# раздел теста
sub header {
	my ($self, $header, $level) = @_;
	$self->println("print $header . \"\\n\";");
}

# преобразовать в regexp кода
sub regexp {
	my ($self, $end) = @_;
	"qr{$end}"
}

# преобразовать в строку кода
sub string {
	my ($self, $end) = @_;
	$end =~ s/["\@\$]/\\$&/g;
	$end =~ s/\\s/ /g;
	"\"$end\"";
}


# преобразовать строку кода
sub scalar {
	my ($self, $end) = @_;
	$end =~ s/;$//;
	"scalar($end)";
}

# из stdout
sub stdout {
	my ($self, $start) = @_;
	my $begin = "::___std(\\*STDOUT); $start; ::___res(\\*STDOUT); ";
	my $start = "::___get()";
	return $begin, $start;
}

# из stderr
sub stderr {
	my ($self, $start) = @_;
	my $begin = "::___std(\\*STDERR); $start; ::___res(\\*STDERR); ";
	my $start = "::___get()";
	return $begin, $start;
}

# из catch
sub catch {
	my ($self, $start) = @_;
	my $begin = "eval { $start }; ";
	my $start = "\$\@";
	return $begin, $start;
}

# из retcode
sub retcode {
	my ($self, $start) = @_;
	my $begin = "$start; ";
	my $start = "\$!";
	return $begin, $start;
}

# test is
sub is {
	my ($self, $start, $end, $desc) = @_;
	"::is( $start, $end, $desc );";
}

# test
sub is_deeply {
	my ($self, $start, $end, $desc) = @_;
	"::is_deeply( $start, $end, $desc );";
}

# test
sub startswith {
	my ($self, $start, $end, $desc) = @_;
	"::is( substr($start, 0, length(\$_ret = $end)), \$_ret, $desc );";
}

# test
sub endswith {
	my ($self, $start, $end, $desc) = @_;
	"::is( substr($start, -length(\$_ret = $end)), \$_ret, $desc );";
}

# test
sub like {
	my ($self, $start, $end, $desc) = @_;
	"::like( $start, $end, $desc );"
}

# test
sub unlike {
	my ($self, $start, $end, $desc) = @_;
	"::unlike( $start, $end, $desc );"
}

# test
sub cmp_ok {
	my ($self, $start, $op, $end, $desc) = @_;
	"::cmp_ok( $start, '$op', $end, $desc );";
}


1;