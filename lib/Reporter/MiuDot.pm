package Reporter::MiuDot;
# обозначает пройденные тесты точками, непройденные - E, ошибки - F

use common::sense;
use EssentialMiu;

# конструктор
sub new {
	my $cls = shift;
	bless {
		@_,
		waserr => 0,
	}, ref $cls || $cls;
}

# на старт!
sub start {
	my ($self) = @_;
	""
}

# выводит сообщение на консоль по каждой строке
sub report {
	my ($self, $result, $current_line) = @_;
	
	my $res = "";
	
	$res .= "." if $result->is_ok;
	$res .= $self->colored("E", "magenta") if $result->is_fail;
	
	$self->{waserr} = 1, $res .= $self->colored("F", "cyan") if $result->is_err && !$self->{waserr};
	$self->{waserr} = 0 if $result->is_test;
	return $res;
}

# тесты прошли
sub ok {
	my ($self) = @_;
	$self->colored(" ok\n", "black", "bold");
}

# тесты не прошли
sub fail {
	my ($self) = @_;
	my $ok = $self->{ok};
	my $fail = $self->{fail};
	my $count = $self->{count_tests};
	my $count_ok = keys %$ok;
	my $count_fail = keys %$fail;
	my $last_tests = $count - $count_ok - $count_fail;
	my @ret;
	push @ret, $self->colored("_" x $last_tests, "black", "bold");
	push @ret, $self->colored(" fail", "red") . "\n";
	
	use List::Util qw/max min/;
	
	my ($line_first, $line_last);
	push @ret, "первая ошибка на ".$self->colored($line_first, "white")." строке\n" if $line_first = min values %$fail;
	push @ret, "последний тест на ".$self->colored($line_last, "white")."\n" if $last_tests and $line_last = max values %$ok, values %$fail;
	return join "", @ret;
}

# раскрашивает, если нужно
sub colored {
	my ($self, $s, @color) = @_;
	return $s if $self->{uncolor};
	EssentialMiu::colored($s, @color);
}

1;