package Miu::File::Js;
# врайтер Javascript

use base Miu::File::Test;

use common::sense;
use Miu::Essential;

# конструктор
sub new {
	my $cls = shift;
	(ref $cls || $cls)->SUPER::new(@_, tab=>"");
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
sub exec_param {
	my ($self, $miu) = @_;	
	return Miu::Essential::executor("node"), $self->{path};
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

# возвращает функцию для вывода
sub printfn {
	"console.log"
}

# раздел теста
sub header {
	my ($self, $header, $level) = @_;
	$self->println($self->printfn . "($header);");
}

# дополняем сохранение
sub before_save {
	my $self = shift;
	
	my $count_tests = $self->{count_tests};
	#my $path = $self->string($self->{path});
	my $log = $self->printfn;
	
	$self->unshift_test("// сгенерировано miu

function deepEqual\$(a, b, path_a, path_b) {
	function ret(a, b, path_a, path_b) {
		return [(path_a? path_a+'='+a: a), (path_b? path_b+'='+b: b)]
	}
	
	function keys(a) {
		var r = []
		for(i in a) if(a.hasOwnProperty(i)) r.push(i)
		return r.sort()
	}

	function jpath(p, l, x) { return p? p+x+l: l }
	
	if(path_a == null) path_a = ''
	if(path_b == null) path_b = ''
	
	var r
	if(a instanceof Array && b instanceof Array) {
		if(a.length !== b.length) return ret(a.length, b.length, path_a+'.length', path_b+'.length')
		for(var i=0, n=a.length; i<n; i++) {
			if(r = deepEqual\$(a[i], b[i], path_a+'['+i+']', path_b+'['+i+']')) return r
		}
		return false
	}
	if(typeof a === 'object' && typeof b === 'object') {
		var ka = keys(a), kb = keys(b)
		if(ka.length !== kb.length) return ret(a, b, path_a+'.keys().length', path_b+'.keys().length')
		for(var i=0, n=ka.length; i<n; i++) {
			var k1 = ka[i], k2 = kb[i]
			if(k1 != k2) return ret(k1, k2, path_a+'.key('+i+')', path_b+'.key('+i+')')
			if(r = deepEqual\$(a[k1], b[k2], path_a+'.'+k1, path_b+'.'+k2)) return r
		}
		return false
	}
	if(a == b) return false
	return ret(a, b, path_a, path_b)
}
	
function assert\$(ok, num, got, op, expected, msg) {
	if(ok) {
		$log('ok '+num+' - '+msg)
	} else {
		$log('not ok '+num+' - '+msg)
		$log('#  Failed test: '+msg)
		$log('#    got:      '+got)
		$log('#    operator: '+op)
		$log('#    expected: '+expected)
	
		var s = new Error().stack.replace(/\\n/g, '\\n#        ')
		$log('#      trace: '+s)
	}
}

var S\$, R\$, E\$;
$log('1..'+$count_tests);
");
	
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
	"S\$ = $start; R\$ = $end; assert\$( S\$ == R\$, $self->{count_tests}, S\$, '=', R\$, $desc );";
}

# test
sub is_deeply {
	my ($self, $start, $end, $desc) = @_;
	"S\$ = deepEqual\$($start, $end); assert\$( !S\$, $self->{count_tests}, S\$ && S\$[0], '~~', S\$ && S\$[1], $desc );";
}

# test
sub startswith {
	my ($self, $start, $end, $desc) = @_;
	"S\$ = String($start); R\$ = String($end); assert\$( S\$.substring(0, R\$.length) == R\$, $self->{count_tests}, S\$, 'startswith', R\$, $desc );";
}

# test
sub endswith {
	my ($self, $start, $end, $desc) = @_;
	"S\$ = String($start); R\$ = String($end); assert\$( S\$.substring(S\$.length-R\$.length) == R\$, $self->{count_tests}, S\$, 'endswith', R\$, $desc );";
}

# test
sub like {
	my ($self, $start, $end, $desc) = @_;
	"S\$ = $start; R\$ = $end; assert\$( R\$.test(S\$), $self->{count_tests}, S\$, '~', R\$, $desc );";
}

# test
sub unlike {
	my ($self, $start, $end, $desc) = @_;
	"S\$ = $start; R\$ = $end; assert\$( !R\$.test(S\$), $self->{count_tests}, S\$, '~', R\$, $desc );";
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
	
	"S\$ = $start; R\$ = $end; assert\$( S\$ $op R\$, $self->{count_tests}, S\$, $orig, R\$, $desc );";
}


1;