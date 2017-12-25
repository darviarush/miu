package MiuRise;
# тесты в виде взлетающего самолёта

use base MiuDot;

use common::sense;

require Term::Screen;

# конструктор
sub new {
	my $cls = shift;
	$cls->SUPER::new( @_, scr => new Term::Screen)
}

# выводит сообщение на консоль по каждой строке
sub report {
	my ($self, $result, $current_line) = @_;
	
	if
	
	return $res;
}


1;