package Miu::Reporter::Rise;
# тесты в виде взлетающего самолёта

use base Miu::Reporter::Dot;

use common::sense;

require Term::Screen;

# конструктор
sub new {
	my $cls = shift;
	$cls->SUPER::new( @_, screen => new Term::Screen)
}

# на старт!
sub start {
	my ($self) = @_;
	
	my $screen = $self->{screen};
	
	return $self->SUPER::start if !$screen;
	
	my $cols = $self->{cols} = $screen->cols;
	my $tests = $self->{count_tests};
	
	my $end = $cols - $tests;
	
	$screen->puts();
	
	print "" . ("-" x $end) . "\n";
	print "" . ("·" x $end) . "\n";
	print "" . ("-" x $end) . "\n";
}

# выводит самолётик
sub report {
	my ($self, $result, $current_line) = @_;
	
	my $screen = $self->{screen};
	
	return $self->SUPER::report($result, $current_line) if !$screen;
	
	#$screen
}


1;