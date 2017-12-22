package MiuJs;
# врайтер Javascript

use base MiuTestFile;

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
	return EssentialMiu::executor("node"), $self->{path};
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
var tape\$ = require('tape');

tape\$.Test.prototype.cmp_ok = function(ok, a, op, b, msg, extra) {
	this._assert(ok, {
		message : (msg? msg: 'should be cmpare '+op),
		operator : op,
		actual : a,
		expected : b,
		extra: extra
	});
};

tape\$.Test.prototype.like = function(a, b, msg, extra) {
	this._assert(b.test(a), {
		message : (msg? msg: 'should be like'),
		operator : '~',
		actual : a,
		expected : b,
		extra: extra
	});
};

tape\$.Test.prototype.unlike = function(a, b, msg, extra) {
	this._assert(!b.test(a), {
		message : (msg? msg: 'should be like'),
		operator : '!~',
		actual : a,
		expected : b,
		extra: extra
	});
};


tape\$($path, function (T\$) {
  var S\$, R\$, E\$;
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
	my ($self, $end, $code) = @_;
	$end =~ s/;$//;
	#$code? "($end)": "String($end)";
	"($end)"
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
	my ($self, $start, $code) = @_;
	my $begin = $code? "E\$ = null; try { $start } catch(e) { E\$ = e } ":
					   "E\$ = null; try { $start } catch(e) { E\$ = e.message } ";
	my $start = 'E$';
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
	"T\$.deepLooseEqual( $start, $end, $desc );";
}

# test
sub is_deeply {
	my ($self, $start, $end, $desc) = @_;
	"T\$.deepLooseEqual( $start, $end, $desc );";
}

# test
sub startswith {
	my ($self, $start, $end, $desc) = @_;
	"S\$ = String($start); R\$ = String($end); T\$.equal( S\$.substring(0, R\$.length), R\$, $desc );";
}

# test
sub endswith {
	my ($self, $start, $end, $desc) = @_;
	"S\$ = String($start); R\$ = String($end); T\$.equal( S\$.substring(S\$.length-R\$.length), R\$, $desc );";
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
	my $orig = $self->string($op);
	
	if($op =~ /^(eq|ne|lt|gt|le|ge)$/) {
		$start = "String($start)";
		$end = "String($end)";
		my %op = qw(eq = ne != lt < gt > le <= gt >=);
		$op = $op{$op};
	}
	
	"T\$.cmp_ok( $start $op $end, $start, $orig, $end, $desc );";
}


1;