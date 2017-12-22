package MiuTestFile;
# базовый класс для тестов

use base MiuFile;

use common::sense;


# конструктор
sub new {
	my $cls = shift;
	$cls->SUPER::new(is_file_code => 0, @_);
}

# устанавливает количество тестов
sub count_tests {
	my ($self, $count_tests) = @_;
	$self->{count_tests}++;	
	$self
}

# парсит строку и возвращает результат для TAP (Test Anithing Protocol)
sub parse {
	my ($self, $s, $stderr) = @_;
	local $_ = $s;
	
	use ResultMiu;
	
	return ResultMiu->new($s, "err") if $stderr;
	return ResultMiu->new($s, "ok", rem=>$`, num=>$1) if /^ok (\d+) (- )?/;
	return ResultMiu->new($s, "fail", rem=>$`, num=>$1) if /^not ok (\d+) (- )?/;
	return ResultMiu->new($s, "plan", pass=>$1, count=>$2) if /^(\d+)\.\.(\d+)/;
	return ResultMiu->new($s, "comment", rem=>$`) if /^#[ \t]/;
	return ResultMiu->new($s, "header", rem=>$`) if /^=+[ \t]+/;
	
	return ResultMiu->new($s, "unknown");
}



1;