package MiuJs;
# врайтер Javascript

use base MiuFile;

use common::sense;
use EssentialMiu;

# конструктор
sub new {
	my $cls = shift;
	(ref $cls || $cls)->SUPER::new(@_, tab=>"  ");
}


# возвращает название языка
sub name {
	"js"
}

# возвращает расширение для файла теста которе будет указано после расширения теста: .t
sub test_ext {
	".js"
}

# возвращает путь к интерпретатору для tap-парсера
sub exec {
	my ($self, $miu) = @_;	
	[$self->executor("node"), $self->{path}]
}

# возвращает символ для регулярки
sub comment {
	"//"
}

# пытается распознать в строке ошибку и отмапить
sub mapiferror {
	my ($self, $s, $miu) = @_;

	my $path = $self->{regexp_path} //= do { my $p = quotemeta $self->{path}; qr!$p:(\d+)! };
	my $lineno;
	if($s =~ $path) {
		my $lineno = $self->{map}[$1-1];
		$s =~ s!$path!$& (AKA $lineno IN $miu->{path})! if defined $lineno;
	}	
	$s
}


# раздел теста
sub header {
	my ($self, $header, $level) = @_;
	$self->println("console.log($header);");
}

# дополняем сохранение
sub before_save {
	my $self = shift;
	
	my $count_tests = $self->{count_tests};
	my $path = $self->string($self->{path});
	
	$self->unshift_test("// сгенерировано miu
var test\$ = require('tape');

test\$($path, function (T\$) {
T\$.plan($count_tests);
");

	$self->println("});", "");
	
	$self
}

# преобразовать в regexp кода
sub regexp {
	my ($self, $end) = @_;
	$end =~ s!/!\\/!g;
	"/$end/"
}

# преобразовать в строку кода
sub string {
	my ($self, $end) = @_;
	$end =~ s/["]/\\$&/g;
	$end =~ s/\\s/ /g;
	"\"$end\"";
}


# преобразовать строку кода
sub scalar {
	my ($self, $end) = @_;
	$end =~ s/;$//;
	"($end)";
}

# из stdout
sub stdout {
	# my ($self, $start) = @_;
	# my $begin = "___std(\\*STDOUT); $start; ___res(\\*STDOUT); ";
	# my $start = "___get()";
	# return $begin, $start;
	TODO
}

# из stderr
sub stderr {
	# my ($self, $start) = @_;
	# my $begin = "___std(\\*STDERR); $start; ___res(\\*STDERR); ";
	# my $start = "___get()";
	# return $begin, $start;
	TODO
}

# из catch
sub catch {
	my ($self, $start) = @_;
	my $begin = "var _ERR\$ = null; try { $start } catch(e) { _ERR\$ = e }";
	my $start = '_ERR$';
	return $begin, $start;
}

# из retcode
sub retcode {
	# my ($self, $start) = @_;
	# my $begin = "$start; ";
	# my $start = "\$!";
	# return $begin, $start;
	TODO
}

# test is
sub is {
	my ($self, $start, $end, $desc) = @_;
	"T\$.is( $start, $end, $desc );";
}

# test
sub is_deeply {
	my ($self, $start, $end, $desc) = @_;
	"T\$.is_deeply( $start, $end, $desc );";
}

# test
sub startswith {
	my ($self, $start, $end, $desc) = @_;
	"T\$.is( substr($start, 0, length(\$_ret = $end)), \$_ret, $desc );";
}

# test
sub endswith {
	my ($self, $start, $end, $desc) = @_;
	"T\$.is( substr($start, -length(\$_ret = $end)), \$_ret, $desc );";
}

# test
sub like {
	my ($self, $start, $end, $desc) = @_;
	"T\$.like( $start, $end, $desc );"
}

# test
sub unlike {
	my ($self, $start, $end, $desc) = @_;
	"T\$.unlike( $start, $end, $desc );"
}

# test
sub cmp_ok {
	my ($self, $start, $op, $end, $desc) = @_;
	"T\$.cmp_ok( $start, '$op', $end, $desc );";
}


1;