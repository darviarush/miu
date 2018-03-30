package Miu::File::Test;
# базовый класс для тестов

use base Miu::File::File;

use common::sense;

use Miu::Essential;

# конструктор
sub new {
	my $cls = shift;
	$cls->SUPER::new(is_file_code => 0, count_tests=>0, current_test=>0, @_);
}

# устанавливает количество тестов
sub count_tests {
	my ($self, $count_tests) = @_;
	$self->{count_tests}++;
	$self->{current_test} = $count_tests;
	$self
}

# запускает тесты
sub exec {
	my ($self, $miu, $parseLine) = @_;
	
	### open3 simple
	use IPC::Open3::Simple;
	my $ipc = IPC::Open3::Simple->new(out=>sub{$parseLine->($_[0], 0)}, err=>sub{$parseLine->($_[0], 1)});
	$ipc->run($self->exec_param($miu));
	
	# ### open3 callback
	# my $stdout = [];
	# my $stderr = [];
	# my $cb = sub {
		# my ($chunk, $std) = @_;
		# while($chunk =~ /(.*)(?:\r\n|\n|\r)/g) {
			# push @$std, $1;
			# $parseLine->(join("", @$std), $std == $stderr);
			# @$std = ();
		# }
		# push @$std, $1 if $chunk =~ /([^\r\n]+)\z/g;
	# };
	
	# $Log::Log4perl::Logger::NON_INIT_WARNED=1;	# Log::Log4perl использует IPC::Open3::Callback
	
	# use IPC::Open3::Callback;
	# my $ipc = IPC::Open3::Callback->new({
		# out_callback => sub { $cb->($_[0], $stdout) }, 
		# err_callback => sub { $cb->($_[0], $stderr) }
	# });
	# $ipc->run_command($codeFile->exec($self));
	
	$self
}

# распознаёт строку и преобразует из неё
sub __from_string ($) {
	my ($s) = @_;
	return $s if $s !~ s/^'//;
	if($s =~ /\\'\s*$/) {
		$s .= "…";
	} else {
		$s =~ s/'\s*$//;
	}
	
	$s =~ s/\\'/'/g;
	$s
}

# парсит строку и возвращает результат для TAP (Test Anithing Protocol)
sub parse {
	my ($self, $s, $stderr) = @_;
	local $_ = $s;
	
	use Miu::Result;
	
	return Miu::Result->new($s, "err") if $stderr;
	return Miu::Result->new($s, "ok", rem=>$', num=>$1) if /^ok (\d+) (- )?/;
	return Miu::Result->new($s, "fail", rem=>$', num=>$1) if /^not ok (\d+) (- )?/;
	return Miu::Result->new($s, "plan", pass=>$1, count=>$2) if /^(\d+)\.\.(\d+)/;
	
	
	
	return Miu::Result->new($s, "got", rem=>__from_string $') if /^#[ \t]+got: /;
	return Miu::Result->new($s, "expected", rem=>__from_string $') if /^#[ \t]+expected: /;
	
	return Miu::Result->new($s, "comment", rem=>$') if /^#[ \t]/;
	return Miu::Result->new($s, "header", rem=>$') if /^=+[ \t]+/;
	
	return Miu::Result->new($s, "unknown");
}


1;