package Miu::File::Jsb;
# врайтер Javascript

use base Miu::File::Js;

use common::sense;
use Miu::Essential;

# конструктор
sub new {
	my $cls = shift;
	(ref $cls || $cls)->SUPER::new(@_, tab=>"");
}


# возвращает название языка
sub name {
	"jsb"
}

# возвращает расширение для файла теста которе будет указано после расширения теста: .t
sub test_ext {
	".browser.js"
}

# запускает тесты в браузере
sub exec {
	my ($self, $miu, $parseLine) = @_;	

	use LWP::Socket;
 
	my $headers = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: close\r\n\r\n";
	my $port = 3000;
	
	# msg1 $self;
	# return;
	
	my $sd = $miu->{sd} //= do {
		my $sd = LWP::Socket->new;
		$sd->bind('127.0.0.1', $port) or die "Can't bind a socket on port $port: $!";
		$sd->listen(10);
		$sd
	};
	
	# выставляем таймаут
	$SIG{ALRM} = sub {};
	alarm 1;
	my $ns = $sd->accept(1);
	if(!$ns) {	# запускаем браузер
		my $command = $miu->{browser} // '"/cygdrive/c/Program Files (x86)/Opera/launcher.exe" %s';
		$command =~ s!%s!http://127.0.0.1:$port!;
		print "$command\n";
		print `$command`;
		sleep 1;
		
		alarm 1;
		$ns = $sd->accept(1) or die "нет запроса от тестовой страницы";
		
		$ns->write( $headers . $self->page );
	} else { # пришёл ajax-запрос от тестовой страницы
		$ns->write( $headers . "ok" );
		$ns->shutdown;
		
		alarm 1;
		$ns = $sd->accept(1) or die "не пришёл запрос после livereload";
		$ns->write( $headers . $self->page );
		$ns->shutdown;
	}
	
	
	
	#$ns->read( $file_name );
	$ns->write( $headers );
	$ns->shutdown;
		
}

# возвращает функцию для вывода
sub printfn {
	"console.log"
}

# 
sub page {
	my ($self) = @_;
	my $title = "Miu test ";
	
	"<!doctype html>
	<html lang=\"en\">
	<head>
		<meta charset=\"UTF-8\">
		<title></title>
	</head>
	<body>
		<h1>$title</h1>
	
		<script>
			function tests() {
				".join("\n				", $self->{codefile})."
			}
		</script>
	</body>
	</html>"
}

1;