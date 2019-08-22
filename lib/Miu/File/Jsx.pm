package Miu::File::Jsx;
# врайтер Javascript

use base Miu::File::Js;

use common::sense;
use Miu::Essential;

# 1. запускаем браузер с адресом сервера miu
# 2. отдаём файл test-jsx
# 3. этот файл проганяет тесты и дёргает ajax-запрос с их результатами
# 4. вкладка с тестами в браузере закрывается


# конструктор
sub new {
	my $cls = shift;
	my $self = (ref $cls || $cls)->SUPER::new(@_, tab=>"");
	
	
	
	$self
}


# возвращает название языка
sub name {
	"jsx"
}

# возвращает расширение для файла теста которе будет указано после расширения теста: .t
sub test_ext {
	".browser.js"
}

# запускает тесты в браузере
sub exec {
	my ($self, $miu, $parseLine) = @_;	
	
	
	# выставляем таймаут
	$SIG{ALRM} = sub {};
	alarm 1;
	
	my $port = $miu->{port} // 7707;
	
	# запускаем сервер
	my $pid = fork;
	die "fork: $!" if $pid < 0;
	if($pid==0) {
		# дочерний процесс
		my $server = Miu::Jsx::Server->new($port);
		$server->run();
	}
	else {
	
		# открываем страницу в браузере
		my $command = $miu->{browser} // '"/cygdrive/c/Program Files (x86)/Opera/launcher.exe" %s';
		
		$command =~ s!%s!http://127.0.0.1:$port!;
		print "$command\n";
		print `$command`;
		sleep 1;
		
	}
	
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
		<script>
			
		</script>
	</body>
	</html>"
}

package Miu::Jsx::Server;

use common::sense;

use base qw/HTTP::Server::Simple::CGI/;

my %dispatch = (
	"/" => sub {
		my $cgi  = shift;
		print "";
	},
	"/results" => sub {
		my $cgi  = shift;
		print "";
	},
);

# обработчик запроса
sub handle_request {
    my $self = shift;
    my $cgi  = shift;
   
    my $path = $cgi->path_info;
    my $handler = $dispatch{$path};
 
    if (ref $handler eq "CODE") {
        print "HTTP/1.0 200 OK\n\n";
        $handler->($cgi);
         
    } else {
        print "HTTP/1.0 404 Not found\n\n";
        print "404 Not Found\n"
    }
}

1;
