package Reporter::MiuDot;
# обозначает пройденные тесты точками, непройденные - E, ошибки - F

use common::sense;
use EssentialMiu;

# конструктор
sub new {
	my $cls = shift;
	bless {
		errorlines => [],
		@_
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
	
	$self->{line_last} = $current_line if $result->is_test;
	
	return "." if $result->is_ok;
	$self->{line_first_fail} //= $current_line, return $self->colored("E", "red") if $result->is_fail;
	
	#print $self->colored("F", "cyan"),
	# push @{$self->{errorlines}}, $result->raw
		# if $result->is_err;
	return;
}

# тесты прошли
sub ok {
	my ($self) = @_;
	$self->colored(" ok\n", "black", "bold");
}

# тесты не прошли
sub fail {
	my ($self, $count_ok, $count_fail) = @_;
	my $last_tests = $self->{count_tests} - $count_ok - $count_fail;
	my @ret;
	push @ret, $self->colored("_" x $last_tests, "black", "bold");
	push @ret, $self->colored(" fail", "red") . "\n";
	push @ret, "первая ошибка на ".$self->colored($self->{line_first_fail}, "white")." строке\n" if defined $self->{line_first_fail};
	push @ret, "последний тест на ".$self->colored($self->{line_last}, "white")."\n" if $last_tests and defined $self->{line_last};
	return join "", @ret;
}

# раскрашивает, если нужно
sub colored {
	my ($self, $s, @color) = @_;
	return $s if $self->{uncolor};
	EssentialMiu::colored($s, @color);
}

1;