package Miu::Result;
# результат парсинга строки вывода теста

use common::sense;

# конструктор
sub new {
	my ($cls, $raw, $type, @args) = @_;
	utf8::decode($raw);
	utf8::decode($type);
	bless {
		type => $type,
		raw => $raw,
		map { utf8::decode($_); $_ } @args
	}, ref $cls || $cls;
}

# неизвестная строка
sub is_unknown {
	my ($self) = @_;
	$self->{type} eq "unknown"
}

# тест прошёл
sub is_ok {
	my ($self) = @_;
	$self->{type} eq "ok"
}

# номер теста
sub num {
	my ($self) = @_;
	$self->{num}
}

# комментарий к строке
sub rem {
	my ($self) = @_;
	$self->{rem}
}

# сообщение о непройденном тесте
sub is_fail {
	my ($self) = @_;
	$self->{type} eq "fail"
}

# тест
sub is_test {
	my ($self) = @_;
	$self->{type} eq "ok" || $self->{type} eq "fail"
}

# количество тестов
sub count {
	my ($self) = @_;
	$self->{count}
}

# сколько прошло тестов
sub pass {
	my ($self) = @_;
	$self->{pass}
}

# строка как есть
sub raw {
	my ($self) = @_;
	$self->{raw}
}

# это строка
sub is_string {
	my ($self) = @_;
	$self->{rem} // $self->{raw}
}

# ошибка в тесте: получено значение
sub is_got {
	my ($self) = @_;
	$self->{type} eq "got"
}

# ошибка в тесте: требуется значение
sub is_expected {
	my ($self) = @_;
	$self->{type} eq "expected"
}

# комментарий Test::More
sub is_comment {
	my ($self) = @_;
	$self->{type} =~ /^(comment|got|expected)$/n
}

# план 1..2
sub is_plan {
	my ($self) = @_;
	$self->{type} eq "plan"
}

# это заголовок статьи
sub is_header {
	my ($self) = @_;
	$self->{type} eq "header"
}

# это ошибка
sub is_err {
	my ($self) = @_;
	$self->{type} eq "err"
}


1;