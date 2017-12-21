package MiuFile;
# файл теста или кода в miu. Базовый для языковых файлов

use common::sense;



# конструктор
sub new {
	my $cls = shift;
	bless {
		path => "",			# путь к файлу
		codefile => [],		# массив строк файла
		map => [],			# маппинг
		is_file_code => 0,	# это файл кода, а не теста
		tab => "",			# отступ строки
		@_
	}, ref $cls || $cls;
}


# количество строк
sub lines {
	my ($self) = @_;
	@{$self->{codefile}}
}

# печатает в текущий файл кода
sub println {
	my ($self, $s, $tab) = @_;
    
	my $path = $self->{path};
    
    die "println: нет пути файла" if !defined $path;
    die "println: неожиданный перевод строки" if $s =~ /\n/;
	
	$s = ($tab // $self->{tab}) . $s;
	
	push @{$self->{codefile}}, $s;
    
    # маппинг строк файла в файле miu
	push @{$self->{map}}, $.;
	
	$self
}

# добавляет заголовок теста
sub unshift_test {
	my ($self, $s) = @_;
    
    my @lines = split /\n/, $s;
    unshift @{$self->{codefile}}, @lines;
    
    # меняем маппинг
    my $map = $self->{map};
    my $fill = $map->[0];
    
    unshift @$map, ($fill) x @lines;

	$self
}

# редактирует строки кода
sub splice {
	my ($self, $from, $count, @lines) = @_;
    
    splice @{$self->{codefile}}, $from, $count, @lines;
    
    # меняем маппинг
    my $map = $self->{map};
    my $fill = $map->[$from];
    
    splice @$map, $from, $count, ($fill) x @lines;

	$self
}


# хук перед сохранением
sub before_save {
}

# записывает всё в файл
sub save {
	my ($self) = @_;
	local $_;
	
	$self->before_save();
	
	
	my $path = $self->{path};
	
	if(!-e $path) {
        # создаём директории
        mkdir $`, 0744 while $path =~ m!/!g;
    }
    
    open my $codeFile, ">:encoding(utf8)", $path or die "Не могу открыть файл ".($self->{is_file_code}? "кода": "теста")." $path: $!";
	print $codeFile join "\n", @{$self->{codefile}};
    close $codeFile;
	
	$self
}


# добавляет опции
sub options {
	my $self = shift;
	
	for(my $i=0; $i<@_; $i+=2) { $self->{$_[$i]} = $_[$i+1] }
	
	$self
}

# возвращает имя драйвера
sub name {
	"file"
}

1;