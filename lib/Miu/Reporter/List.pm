package Miu::Reporter::List;
# тесты в виде списка с относительным временем

use base Miu::Reporter::Dot;

use common::sense;
use Time::HiRes qw/time/;


# конструктор
sub new {
	my $cls = shift;
	$cls->SUPER::new( @_ )
}

# на старт!
sub start {
	my $self = shift;
	$self->{time} = time();
	print "\n";
}

# выводит сообщение на консоль по каждой строке
sub report {
	my ($self, $result, $current_line) = @_;
	my $time;
	
	# 🕅
	print $self->colored("§" x length(($result->raw =~ /^([#=]+)/)[0]), "cyan") . " ". $self->colored($result->rem,  "bold", "black") . "\n" if $result->is_header;
	print $self->colored("   ✓ ", "green") . $self->gettime . $result->is_string . "\n" if $result->is_ok;
	print $self->colored("   × ", "red") . $self->gettime . $result->is_string . "\n" if $result->is_fail;
	
	print $self->colored("    · ", "yellow") . $self->colored($result->raw, "bold", "black") ."\n" if $result->is_unknown;
	print "    " . ($result->{key}? $self->colored($result->{key}, "black bold")." ": "") . $self->colored("≠ ", "white") . $self->colored($result->rem, "red") ."\n" if $result->is_got;
	
	#print $self->colored("must by: ", "white") . $self->colored($result->rem, "bold black") ."\n" if $result->is_expected;
	
}

# возвращает время потраченное на тест
sub gettime {
	my ($self) = @_;
	my $t = time() - $self->{time};
	$self->{time} = time();
	
	my $f = "";
	if( int($t)>0 ) {}
	#elsif( int($t*10)>0 ) { $t*=10; $f="d" }
	#elsif( int($t*100)>0 ) { $t*=100; $f="c" }
	elsif( int($t*1000)>0 ) { $t*=1000; $f="m" }
	elsif( int($t*1000_000)>0 ) { $t*=1000_000; $f="µ" }
	elsif( int($t*1000_000_000)>0 ) { $t*=1000_000_000; $f="n" }
	elsif( int($t*1000_000_000_000)>0 ) { $t*=1000_000_000_000; $f="p" }
	
	$t = sprintf("%.2f", $t);
	
	$self->colored("${t} ${f}s\t", "bold", "black")
}

1;