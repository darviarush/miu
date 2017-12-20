package EssentialMiu;
# необходимые функции для разработки

use common::sense;
use Term::ANSIColor qw/colored color/;

# импортирует в вызывавший модуль функции
my %EXPORT = (map {$_=>1} qw/TODO msg msg1 colored color/);
sub import {
	my $self = shift;
	
	my $caller = caller;
	
	require warnings;
	
	my $once = $warnings::Offsets{'once'};
	
	my $save = vec(${^WARNING_BITS}, $once, 1);
	
	for my $name (@_? @_: keys %EXPORT) {
		my $v = $EXPORT{$name};
		die "нет такого имени `$name`" if !defined $v;
		
		if($v == 0) {
			*{"${caller}::$v"} = \${$v};
		}
		else {
			*{"${caller}::$name"} = \&$name;
		}
	
	}
	
	vec(${^WARNING_BITS}, $once, 1) = $save;
	
	#${^WARNING_BITS} ^= ${^WARNING_BITS} ^ ;
	vec(${^WARNING_BITS}, $warnings::Offsets{'recursion'}, 1) = 1;
	
	$self;
}


sub TODO () {
	my ($pkg, $file, $line, $sub) = caller(1);
	print STDERR "не используется $sub\n";
	return
}

# сообщение на консоль
sub msg {
	use Data::Dumper;
	local ($_, $`, $', $1);
	my $color;
	print STDERR join ", ", map { ref $_ ne ""? Dumper($_): /^:(\w+(?:\s+\w+)*)$/? color($color = $1): $_} @_;
	print STDERR color("reset") if $color;
	print STDERR "\n";
	return $_[0];
}


# 
sub msg1 {
	print STDERR colored(["yellow on_red"], "=============") . " ";
	goto &msg;
}

1;