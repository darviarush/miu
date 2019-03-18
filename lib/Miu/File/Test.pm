package Miu::File::Test;
# базовый класс для тестов

use base Miu::File::File;

use common::sense;

use Miu::Essential;

no utf8;

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

# открывает pipe
use POSIX qw(:errno_h :fcntl_h :sys_wait_h);
sub _pipe {
	my ($STD) = @_;
	
	pipe my $RH, my $WH or die $!;
	select $RH; $|=1; select STDOUT;
	
	fcntl $RH, F_GETFL, my $flags or die $!;
	$flags |= O_NONBLOCK;
	fcntl $RH, F_SETFL, $flags or die $!;
	
	open my $SAVESTD, ">&", $STD or die $!;
	close $STD or die $!;
	open $STD, ">&", $WH or die $!;
	
	return ($RH, $SAVESTD);
}

# закравает pipe
sub _reset_pipe {
	my ($STD, $SAVESTD) = @_;
	close $STD or die $!;
	open $STD, ">&:utf8", $SAVESTD or die $!;
}

# запускает тесты
sub exec {
	my ($self, $miu, $parseLine) = @_;
	
	my @argv = map { utf8::encode($_); $_ } $self->exec_param($miu);
	my $X = shift @argv;
	
	my ($xname) = $X =~ /([^\/]+)$/;
	
	use Proc::FastSpawn;
	fd_inherit $_ for (1,2);	# для STDERR и STDOUT
	
	my ($STDOUT, $SOUT) = _pipe(\*STDOUT);
	my ($STDERR, $SERR) = _pipe(\*STDERR);

	my $pid = spawn $X, [$xname, @argv];
	
	_reset_pipe(\*STDERR, $SERR);
	_reset_pipe(\*STDOUT, $SOUT);
	
	my $stdout = [];
	my $stderr = [];
		
	my $cb = sub {
		my ($chunk, $std) = @_;
		
		my $i=0;
		while($chunk =~ /(.*?)(?:\r\n|\n|\r)/gs) {
			$i++;
			push @$std, $1;
			$parseLine->(join("", @$std), $std == $stderr);
			@$std = ();
		}
		push @$std, $' if $i && length $';
		push @$std, $chunk if !$i && length $chunk;
	};
	
	my $rin = my $win = my $ein = '';
    vec($rin, fileno($STDERR), 1) = 1;
    vec($rin, fileno($STDOUT), 1) = 1;
    $ein = $rin | $win;
	
	while() {
		select(my $rout = $rin, my $wout = $win, my $eout = $ein, 0.25);
		
		read $STDERR, my $res, 1024*1024;
		if(length $res) {
			#utf8::encode($res) if utf8::is_utf8($res);
			$cb->($res, $stderr);
		}
		
		read $STDOUT, my $res, 1024*1024;
		if(length $res) {
			#utf8::encode($res) if utf8::is_utf8($res);
			$cb->($res, $stdout);
		}
		
		last if waitpid($pid, WNOHANG) > 0;
	}
	
	$parseLine->(join("", @$stderr), 1) if @$stderr;
	$parseLine->(join("", @$stdout), 0) if @$stdout;

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

# снимает лишние escape-последовательности
sub __from_comment ($) {
	my ($s) = @_;
	$s =~ s/\\#/#/g;
	$s =~ s/\\\\n/\\n/g;
	$s
}

# парсит строку и возвращает результат для TAP (Test Anithing Protocol)
sub parse {
	my ($self, $s, $stderr) = @_;
	local $_ = $s;
	
	use Miu::Result;
	
	return Miu::Result->new($s, "err") if $stderr;
	return Miu::Result->new($s, "ok", rem=>__from_comment $', num=>$1) if /^ok (\d+) (- )?/;
	return Miu::Result->new($s, "fail", rem=>__from_comment $', num=>$1) if /^not ok (\d+) (- )?/;
	return Miu::Result->new($s, "plan", pass=>$1, count=>$2) if /^(\d+)\.\.(\d+)/;
	
	return Miu::Result->new($s, "got", key => $1, rem=>__from_string __from_comment $') if /^#[ \t]+\$got->([^=]+) = /;
	return Miu::Result->new($s, "expected", key => $1, rem=>__from_string __from_comment $') if /^#[ \t]+\$expected->([^=]+) = /;
	
	
	
	return Miu::Result->new($s, "got", rem=>__from_string __from_comment $') if /^#[ \t]+got: /;
	return Miu::Result->new($s, "expected", rem=>__from_string __from_comment $') if /^#[ \t]+expected: /;
	
	return Miu::Result->new($s, "comment", rem=>__from_comment $') if /^#[ \t]/;
	return Miu::Result->new($s, "header", rem=>__from_comment $') if /^=+[ \t]+/;
	
	return Miu::Result->new($s, "unknown");
}


1;