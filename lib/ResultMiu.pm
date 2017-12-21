package ResultMiu;
# результат парсинга строки вывода теста

use common::sense;

# конструктор
sub new {
	my ($cls, $raw, $type, @args) = @_;
	bless {
		type => $type,
		raw => $raw,
		@args
	}, ref $cls || $cls;
}

# 
sub is_unknown {
	my ($self) = @_;
	$self->{type} eq "unknown"
}

# 
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

# 
sub is_fail {
	my ($self) = @_;
	$self->{type} eq "fail"
}

# 
sub is_test {
	my ($self) = @_;
	$self->{type} eq "ok" || $self->{type} eq "fail"
}

# 
sub count {
	my ($self) = @_;
	$self->{count}
}

# 
sub pass {
	my ($self) = @_;
	$self->{pass}
}

# 
sub raw {
	my ($self) = @_;
	$self->{raw}
}

# 
sub is_string {
	my ($self) = @_;
	$self->{rem} // $self->{raw}
}

# 
sub is_comment {
	my ($self) = @_;
	$self->{type} eq "comment"
}

# 
sub is_plan {
	my ($self) = @_;
	$self->{type} eq "plan"
}

# 
sub is_header {
	my ($self) = @_;
	$self->{type} eq "header"
}

# 
sub is_err {
	my ($self) = @_;
	$self->{type} eq "err"
}


1;