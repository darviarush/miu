# класс
package RrruMiu;

our $VERSION = "0.01";

use common::sense;

BEGIN {
	require Carp;
	$SIG{__DIE__} = sub { Carp::croak($_[0]) };
}

use Cwd qw//;
use Guard;
require File::Find;

use Miu::Essential;

binmode STDIN,  ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

for my $arg (@ARGV) {
	utf8::decode($arg);
}

BEGIN {
	select(STDERR);	$| = 1;
	select(STDOUT); $| = 1; # default
}

sub DESTROY {
	my $self = shift;
	$self->{sd}->close if $self->{sd};
}

#msg1(":green", "✓·×  🙌 🐈 🐱 😼 😹 😾 😾 😻 😺");

# 🐈
# Кот
# Различные символы и пиктограммы
# U+1F408&#128008;Копировать
# 🐱
# Морда кота
# Различные символы и пиктограммы
# U+1F431&#128049;Копировать
# 😼
# Кот с кривой улыбкой
# Эмотикон (эмоджи)
# U+1F63C&#128572;Копировать
# 😹
# Лицо кота со слезами радости
# Эмотикон (эмоджи)
# U+1F639&#128569;Копировать
# 😾
# Кот, надувший губы
# Эмотикон (эмоджи)
# U+1F63E&#128574;Копировать
# 😿
# Плачущий кот
# Эмотикон (эмоджи)
# U+1F63F&#128575;Копировать
# 🙀
# Усталый кот
# Эмотикон (эмоджи)
# U+1F640&#128576;Копировать
# 𐇬
# Фестский диск - кот
# Символы фестского диска
# U+101EC&#66028;Копировать
# 😸
# Ухмыляющийся кот со смеющимися глазами
# Эмотикон (эмоджи)
# U+1F638&#128568;Копировать
# 😺
# Улыбающийся кот с открытым ртом
# Эмотикон (эмоджи)
# U+1F63A&#128570;Копировать
# 😽
# Кот, целующийся с закрытыми глазами
# Эмотикон (эмоджи)
# U+1F63D&#128573;Копировать
# 😻
# Улыбающийся кот с глазами-сердечками
# Эмотикон (эмоджи)

# use POSIX qw/INT/;
# $SIG{INT} = sub {
	# kill -INT, $$;
# };

# конструктор
sub new {
	my $cls = shift;
	bless {
		@_,
		lang => {},			# драйверы языков программирования
	}, $cls
}

# перестраивает паттерны
sub build_patterns ($) {
	my ($patterns) = @_;
	for my $art_pattern (@$patterns) {
		$art_pattern =~ s/^(\^)?(.*?)(\$)?$/$2/;
		my ($add, $sub);
		$add = "^[=#]+\\s*" if $1;
		$sub = "\\s*\$" if $3;
		
		my $x = quotemeta $art_pattern;
		$x =~ s!(\\?\s)+!\\s+!g;
		$art_pattern = qr/$add$x$sub/i;
	}
}

# парсит параметры командной строки
sub parse {
	my $self = shift;

	use Getopt::Long qw/:config no_ignore_case bundling/;

	my $rcfile = ".rrrumiurc";
	
	my $ini = -e $rcfile? inputini($rcfile): {};
	
	my %opt = (
		miu_dir		=> "miu",
		out_dir 	=> ".miu",
		menu 		=> 1,
		submenu 	=> 1,
		%$ini
	);
	
	GetOptions(
		#"p|public" => \$opt{public},
		"a|article" => \$opt{article_only},
		"t|test" => \$opt{test},
		"i|inspect:s" => \$opt{inspect},
		"l|log" => \$opt{log},
		"s|stat" => \$opt{stat},
		"m|miu_dir=s" => \$opt{miu_dir},
		"o|out_dir=s" => \$opt{out_dir},
		"L|lib_dir=s" => \$opt{lib_dir},
		"T|t_dir=s" => \$opt{t_dir},
		"R|run_dir=s" => \$opt{run_dir},
		"I|include_dirs=s" => \$opt{include_dirs},
		"G|log_dir=s" => \$opt{log_dir},
		"A|article_dir=s" => \$opt{article_dir},
		"c|uncolor" => \$opt{uncolor},
		"N|menu" => \$opt{menu},
		"S|submenu" => \$opt{submenu},
		"r|reporter=s" => \$opt{reporter},
		"B|browser=s" => \$opt{browser},
		"C|uncover" => \$opt{uncover},
		"F|cover_dir=s" => \$opt{cover_dir},
		"w|watch" => \$opt{watch},
		"M|mk_config" => \$opt{mk_config},
		"h|help" => \$opt{help},
	);

	# дефолтные значения
	$opt{out_dir} =~ s!/$!!;
	my $out_dir = $opt{out_dir};
	
	$opt{lib_dir} 		//= "$out_dir/lib";
	$opt{t_dir}			//= "$out_dir/t";
	$opt{run_dir}		//= $opt{lib_dir};
	$opt{include_dirs}	//= $opt{lib_dir};
	$opt{log_dir}		//= "$out_dir/log";
	$opt{cover_dir}		//= "$out_dir/cover_db";
	$opt{article_dir}	//= "$out_dir/mark";
	
	my @dirs = qw/out_dir lib_dir t_dir log_dir article_dir/;
	if(grep {defined $opt{$_}} qw/article_only test inspect log stat uncolor/) {
		mkpath "$opt{$_}/" for @dirs;
	} else {
		readypath "$opt{$_}/" for @dirs;
	}

	# преобразум пути
	$opt{include_dirs} = [ map { 
		mkpath "$_/";		# для abs_path
		Cwd::abs_path($_);
	} split /,/, $opt{include_dirs} ];
	
	# удаляем / у директорий
	for my $k (keys %opt) {
		$opt{$k} =~ s!/$!! if $k =~ /_dir$/;
	}
	
	# маска файлов, маска заголовков
	$opt{pattern} = [ split /:/, shift @ARGV ];
	$opt{art_pattern} = [@ARGV];

	build_patterns $opt{art_pattern};
	
	%$self = (%opt, %$self);
	
	return $self;
}

# парсит и запускает тесты
sub run {
	my ($self) = @_;	
	
	if($self->{help}) {
		print "[rrru]miu [опции] [маски_файлов] [маска_разделов]...

rrrumiu 🙌 компилирует файлы в код, тесты и статьи. Выполняет тесты

маски_файлов задаются через \":\"

ОПЦИИ
    -a, --article         не выполнять тесты: только компилировать
    -t, --test            не компилировать: выполнить тесты
    -i, --inspect[=n-k|l] тест в stdout. n - от строки, k - до строки. l - строка
    -l, --log             лог в stdout
    -s, --stat            статистику в stdout
    -m, --miu_dir=dir     директория с тестами-статьями miu
    -o, --out_dir=dir     директория вывода
    -T, --t_dir=dir       директория для скомпиллированных тестов (.t)
    -L, --lib_dir=dir     директория для файлов на @@...
    -R, --run_dir=dir     текущий каталог при выполнении тестов
    -G, --log_dir=dir     директория для логов
    -A, --article_dir=dir директория для статей (.md)
    -N, --menu            создавать ссылки в реадме-файле
    -S, --submenu         создавать оглавление в статьях
    -c, --uncolor         отключить цвет
    -r, --reporter=name   указать формат выдачи на консоль (dot, list)
    -B, --browser=command указать команду для запуска браузера ('/bin/chrome %s')
    -w, --watch           выполнять тесты из изменившейся главы
    -M, --mk_config       созать конфиг
    -h, --help            эта справка 🐈
";
		return;
	}
	
	if($self->{mk_config}) {
		print("🙌 конфиг уже есть\n"), return if -e ".rrrumiurc";
		my $f = Cwd::abs_path(__FILE__);
		$f =~ s!/lib/RrruMiu.pm$!/.rrrumiurc!;
		output ".rrrumiurc", input $f;
		print "🙌 конфиг создан\n";
		return;
	}
	
	if(!$self->{watch}) {
		$self->cover_delete;
		$self->mainfind(\&prepare);
		if($self->{count_tests} == 0) {
			print "🙌 не найдено ни одного теста\n";
		} elsif($self->{err}) {
			#print "Тест провалился\n";
		} else {
			$self->cover_report;
		}
		
		exit $self->{err};
	}
	
	$self->watch(\&prepare);
}

# удаляет базу покрытия
sub cover_delete {
	my ($self) = @_;
	system "cover -silent -delete '$self->{cover_dir}'" if !$self->{uncover};
	$self
}

# строит отчёт покрытия
sub cover_report {
	my ($self) = @_;
	
	return $self if $self->{uncover};
	my $exit_code = system "cover -silent -report html_basic '$self->{cover_dir}'";
	if($exit_code == 0) {
		my $dir = Cwd::abs_path($self->{cover_dir});
		print "Отчёт покрытия: file://$dir/coverage.html\n";
	}
	
	$self
}

# парсим файл и переписываем
sub prepare {
	my ($self, $path) = @_;
	
	$self->{path} = $path;
	$path =~ s/^${\quotemeta $self->{miu_dir}}\/?//;	# удаляем директорию
	$self->{miu_path} = $path;
	
	print "$path ";
	
	# формируем выходные параметры
	$_ = $path;
	s/(?:\.miu)?\.\w+$//i;					# удаляем расширение
	$self->{miu_file} = $_;
	
	if($self->{log}) {
		my $log_file = "$self->{log_dir}/$self->{miu_file}.log";
		if(-e $log_file) {
			print input $log_file;
		} else {
			print "🙌 лог-файл не сформирован\n";
		}
		return $self;
	}
	
	if($self->{stat}) {
		my $stat_file = "$self->{log_dir}/$self->{miu_file}.stat";
		if(-e $stat_file) {
			print input $stat_file;
		} else {
			print "🙌 стат-файл не сформирован\n";
		}
		return $self;
	}
	
	$self->{article_path} = "$self->{article_dir}/$_.markdown";
	$self->{test_path} = "$self->{t_dir}/$_.t";
	$self->{code_path} = "$self->{bin_dir}/$_.pl";
	
	$self->compile if !$self->{test};
	
	if(defined $self->{inspect}) {
		# Syntax::Highlight::Engine::Simple
		# 
		#`/usr/bin/env mcedit "$self->{test_path}"`;
		#if($? != 0) {
		
		my ($from, $to) = split /-/, $self->{inspect};
		
		$to //= $from;
		
		print "\n";
		open my $f, "<:utf8", $self->{test_path} or die "не открыт файл теста $self->{test_path}: $!";
		while(<$f>) {	
			if( $from eq "" || $. >= $from && $. <= $to ) {
				print join "", $., "\t", $_;
			}
		}
		close $f;
		#}			
	}
	else {
		if($self->{article_only}) {
			print "\n";
		} else {
			$self->test;
		}
		
	}
	
	$self->clear;
	
	$self
}


# разбивает файл на 3 части: код, тест и документацию
sub compile {
	my ($self) = @_;
	
    # открываем файл
	my $path = $self->{path};
	open my $file, "<:encoding(utf8)", $path or die "Не могу открыть файл miu $path: $!";
		
    # переходим на тест
    $self->totest;
        
	# подготавливаем разбитие по разделам статьи
	my @art_pattern = @{$self->{art_pattern}};
	my $test_write = @art_pattern? 0: 1;
	my $init = 0;
	
	# разбиваем
	my $thisIsArticle = 1;
	my ($thisIsTest, $thisIsCode) = (1,0);
	my @article;
	my @menu;
	my $count_tests = 0;
	my $lines = $self->{lines} = {};
	my $lang = "perl";
	
	require Miu::Ext;


	while(<$file>) {
		
		if(/^\[test(?:\s+(\w+))?\]\s*$/) {
			($init, $thisIsCode, $thisIsTest) = (0,0,1);
			$self->totest($1);
			$lang = $self->{codeFile}->name;
			push @article, "```\n\n" if !$thisIsArticle;
			$thisIsArticle = 1;
			next;
		}
		
		($init, $thisIsCode, $thisIsTest) = (1,0,1), $self->toinit, next if /^\[init\]\s*$/;
		
		if(/^\@\@(.*?)\s*$/) {
			my $include_file = $1;
			($init, $thisIsCode, $thisIsTest) = (0,1,0);
			
			push @article, "```\n\n" if !$thisIsArticle;
			$thisIsArticle = 1;
			
			push @article, "`\@\@$include_file`\n";
			
			$lang = Miu::Ext->get_lang($include_file);
			
			$self->tocode($include_file);
			next;
		}
        

		my $detectEmptyLine = /^\s*$/;
	
		my $thisIsHeader = s/^([=#]+)(\s+)/ ("#" x length $1) . $2 /e;
		my $level = length $1;
		
		if($thisIsHeader) {
			my $x = $';
			$x =~ s/\s*$//;
			push @menu, (@menu+1).". [$x](#$x)\n";
		}
	
		if($thisIsHeader && $test_write) {
			my $text = $';
			my $header = $text;
			$header =~ s/\s+$//g;
			$header = ("=" x $level) . " " . $header;
			$header = $self->{codeFile}->string($header);
			
			$self->{codeFile}->header($header, $level, $text);
		}
	
		if(s/^(\t| {4})// && !$detectEmptyLine) {
			
			push @article, sprintf("\n```%s\n", $lang) if $thisIsArticle;
		
			$thisIsArticle = 0;
		} elsif(!$detectEmptyLine) {
			push @article, "```\n\n" if !$thisIsArticle;
			$thisIsArticle = 1;
		}
		
		push @article, $_;
        
		if(@art_pattern && $thisIsHeader) {
            $test_write = 0 if $level <= $test_write;
			for my $art_pattern (@art_pattern) {
				$test_write = $level, last if $_ =~ $art_pattern;
			}
		}
		
        s!\s+$!!;
        
		######### [тест или код]
		if(!$thisIsArticle) {
		
			###################### [code]
			if($thisIsCode) {
                $self->{codeFile}->println($_);
			}
			
			###################### [test]
			elsif($thisIsTest && ($test_write || $init)) {

				my $oper = "gt|lt|ne|eq|le|ge|==|!=|>|<|<=|>=|~|!~|startswith|endswith";
				my $comment = $self->{codeFile}->comment;	# возвращает # для perl или // для js
				if(/^\s*#/) {
					$self->{codeFile}->println($_);
				}
				elsif( /^
					\s* (.*?) ;* 
					[\ \t]+ $comment (\#)? 
					(?:
						(?:
							($oper)
							|
							(\@|!|>>|&>)	(?: [\ \t]+ ($oper))?
						)
						
						[\ \t]+
					)?
					(.*?) $
					/x ) {
					$self->{codeFile}->count_tests(++$count_tests);
					
					$lines->{"$self->{codeFile}{path}-$self->{codeFile}{count_tests}"} = $.;
					
					my ($start, $code, $op, $who, $op2, $end) = ($1, $2, $3, $4, $5, $6);
					
					$op //= $op2;
					
					$end =~ s/^\s*(.*?)\s*$/$1/;	# избавляемся от начальных и конечных пробелов
										
					if(!$code) {
					
						if($op eq "~" or $op eq "!~") {
							$end = $self->{codeFile}->regexp($end);
						} else {
							$end = $self->{codeFile}->string($end);
						}
						
					}
					else {
						$end = $self->{codeFile}->scalar($end, $code)
					}
					
					
					my $_test = "";
					my $_cmp = "";
					my $begin = "";
                    
					# if(defined $fileno) { # 6>
						# unshift @test, "___std($fileno);\n";
						# push @test, $start, "; ___res($fileno);\n";
						# $start = "___get()";
					# }
					if($who eq ">>") {	    #STDOUT
                        ($begin, $start) = $self->{codeFile}->stdout($start, $code);
					}
					elsif($who eq "&>") {	#STDERR
						($begin, $start) = $self->{codeFile}->stderr($start, $code);
					}
					elsif($who eq "\@") {
						($begin, $start) = $self->{codeFile}->catch($start, $code);
					}
					elsif($who eq "!") {
						($begin, $start) = $self->{codeFile}->retcode($start, $code);
					}
					
					$start = $self->{codeFile}->scalar($start, $code);

					my $desc = $_;
					#$desc =~ s/\\[nrt]/\\$&/g;
					$desc = $self->{codeFile}->string($desc);
					
					$self->{codeFile}->println(
						$begin . do {
							if(!$op && !$code) {
								$self->{codeFile}->is($start, $end, $desc);
							} elsif(!$op) {
								$self->{codeFile}->is_deeply($start, $end, $desc);
							} elsif($op eq "startswith") {
								$self->{codeFile}->startswith($start, $end, $desc);
							} elsif($op eq "endswith") {
								$self->{codeFile}->endswith($start, $end, $desc);
							} elsif($op eq "~") {
								$self->{codeFile}->like($start, $end, $desc);
							} elsif($op eq "!~") {
								$self->{codeFile}->unlike($start, $end, $desc);
							} else {
								$self->{codeFile}->cmp_ok($start, $op, $end, $desc);
							}
						}
					);
				}
				else {
					$self->{codeFile}->println($_);
				}
			}
		}
	}

	push @article, "```\n\n" if !$thisIsArticle;

	close $file;    # закрываем файл miu
	
    # заполняем файлы кода и тестов, очищаем codeFile и codeFiles
    $self->save;
	
	my $path = $self->{miu_path};
	$path =~ s!-!/!g;
	$path =~ s!/(\w)!"/".uc $1!ge;
	$path =~ s!(\.[^/\.]+)+$!.pm!;
	$path = "lib/$path";
	
	if(-e $path) {
		my $mark = join "", @article;

		use Markdown::To::POD 'markdown_to_pod';
		use List::Util qw/pairmap/;
		
		my $pod = join "", pairmap { 
			my $pod = markdown_to_pod($a);
			$pod =~ s!\bCL+<!L<!g;
			($pod, join "\n", map {"\t$_"} split /\n/, $b) 
		} split /```.*/, $mark;
		
		my $pm = input $path;
		$pm =~ s!((\n__END__\n).*)?$!$2\n=encoding utf-8\n\n$pod!s;
		output $path, $pm;
	}
	
	if($self->{menu} && $self->{readme} eq $self->{miu_path}) {
		my $article_dir = $self->{article_dir};
		push @article, "\n\n## Документация\n\n";
		
		find {
			return if !-f $_;
			return if input($_) !~ /^([=#])+[ \t]+(.*)/m;
			my $head = $2;
			$head =~ s!\s*$!!g;
			s!(?:\.miu)?\.\w+$!.markdown!;
			s!^$self->{miu_dir}/?!!;
			push @article, "1. [$head]($article_dir/$_)\n";
		} $self->{miu_dir};
		
		my $x = "Документация";
		push @menu, (@menu+1).". [$x](#$x)\n";
	}
	
	if($self->{submenu}) {
		splice @article, 1, 0, "## Меню\n", @menu;
	}
	
	# статья-файл
	mkpath $self->{article_path};
	output $self->{article_path}, \@article, "Не могу записать файл статьи %s: %s";
	output "README.md", \@article, "Не могу записать %s: %s" if $self->{readme} eq $self->{miu_path};
	
	
	
	# if(exists $Text::{"Markdown::"}) {
	
		# my @alines;
		# my @bbcode;
		# my @code;
		# my $thisIsCode;
		# for my $line (@article) {
			# if($line =~ /\n```[a-z]\w*\n\n/i) {
				# $thisIsCode = 1;
				# next;
			# }
			
			# if($line eq $end_code) {
				# push @alines, @code;
				# @code = ();
				# $thisIsCode = 0;
				# next;
			# }

			# if($thisIsCode) {
				# push @code, "\t$line";
			# } else {
				# push @alines, $line;
			# }
		# }
	
		# my $article = join "", @alines;
		
		# my $m = Text::Markdown->new;
		# my $html = $m->markdown($article);
		
		# # статья в формате html	
		# open my $articleFile, ">:encoding(utf8)", $self->{html_path} or die "Не могу открыть файл статьи $self->{html_path}: $!";
		# print $articleFile $html;
		# close $articleFile;
	
		# my $bbcode = $self->markdown2bbcode($html);
		
		# # статья в формате bbcode
		# open my $articleFile, ">:encoding(utf8)", $self->{bbcode_path} or die "Не могу открыть файл статьи $self->{bbcode_path}: $!";
		# print $articleFile $bbcode;
		# close $articleFile;
		
		# $bbcode = $self->markdown2bbcode($html, "LOR");
		# # статья в формате lorcode
		# $_ = $self->{bbcode_path};
		# s!\.\w+$!.lorcode!;
		# open my $articleFile, ">:encoding(utf8)", $_ or die "Не могу открыть файл статьи $_: $!";
		# print $articleFile $bbcode;
		# close $articleFile;
		
	# }
	
	
	
	$self->{count_tests} = $count_tests;
	$self
}


# тестирует указанные тесты
# возвращает 1/0 - тест прошёл-не прошёл и выводит в лог
sub test {
	my ($self) = @_;
	
	local $_;
	
	my @tests = sort { $a->name cmp $b->name } grep {!$_->{is_file_code}} values %{$self->{codeFiles}};

	my $path = $self->{test_path};
	
	my $log_path = mkpath "$self->{log_dir}/$self->{miu_file}.log";
	open my $log, ">:utf8", $log_path or die "Не могу открыть лог $log_path: $!";
	
	my $stat_path = mkpath "$self->{log_dir}/$self->{miu_file}.stat";
	open my $stat, ">:utf8", $stat_path or die "Не могу открыть лог $stat_path: $!";

	my $current_test;
	my $current_line;
	my %ok = ();
	my %fail = ();
	my $count_tests = $self->{count_tests};
	$self->{reporter} //= "Dot";
	my $reporter = "Miu/Reporter/" . ucfirst(lc $self->{reporter}) . ".pm";
	eval {require $reporter};
	print("нет обозревателя $self->{reporter}:\n$@\n"), $self->{reporter} = "dot", require "Miu/Reporter/Dot.pm" if $@;
	
	my $class = "Miu::Reporter::" . ucfirst(lc $self->{reporter});
	
	my $reporter = $class->new(
		uncolor=>$self->{uncolor}, 
		count_tests=>$count_tests,
		lines => $self->{lines},
		ok => \%ok,
		fail => \%fail,
		path => $self->{path},
	);
	$reporter->start;

	for my $codeFile (@tests) {
		my $path = $codeFile->{path};

		# парсер каждой строки: объединяет процесс выполнения тестов и вывод отчёта
		my $parseLine = sub {
			my ($s, $stderr) = @_;
			
			utf8::decode($s);
			#msg utf8::is_utf8($s);
			
			my $result = $codeFile->parse($s, $stderr);
			
			if( $result->is_test ) {
				$current_test = $codeFile->{path} . "-" . $result->num;
				$current_line = $self->{lines}{$current_test};
				print $stat "$current_line: ";	# if $self->{log} || $self->{stat};
				print $log "$current_line: ";
			}
			
			$reporter->report($result, $current_line);# if !$self->{log} && !$self->{stat};
			
			$ok{$current_test} = $current_line if $result->is_ok;
			$fail{$current_test} = $current_line if $result->is_fail;
			
			
			# по логам
			$s = $codeFile->mapiferror($s, $self);
			my $s_stat = ($self->{uncolor}? $result->{type}: colored($result->{type}, "cyan")) . " $s\n";
			print $stat $s_stat;
			print $log "$s\n";
		};
		
		# выполняем тест-файлы в отдельных процессах. На каждую строку вывода должна запускаться $parseLine
		my $save_cwd = &Cwd::cwd;
		my $guard_cwd = guard {	chdir $save_cwd };
		chdir $self->{run_dir};
		$codeFile->exec($self, $parseLine);
		undef $guard_cwd;
	}
	
	close $log;
	close $stat;
	
	if(keys(%ok) == $count_tests && $count_tests != 0) {
		$reporter->ok;
	}
	else {
		$reporter->fail;
	}
	
	$self->{err} = 1, $self->{stop} = 1, return if keys(%ok) != $count_tests;
	
	return 1;
}


# публикует в интернете: хабре и т.д.
sub post {
	...
}

# возвращает директории и маски файлов
sub bypattern {
	my ($self) = @_;
	my @pattern = @{$self->{pattern}};
	
	my $miu_dir = $self->{miu_dir};
	my $dirs = [];
	my $re = [];
	
	for my $pattern (@pattern) {
		my ($dir, $mask);
		if($pattern =~ m!(.*)/!) {
			$dir = "$miu_dir/$1/";
			$mask = $';
			push @$dirs, $dir if !($dir ~~ $dirs);
		} else {
			$dir = "$miu_dir/";
			$mask = $pattern;
		}

		$dir = quotemeta $dir;
		
		my ($add, $sub);
		$add = "[^/]*" if $mask !~ s/^\^//;
		$sub = "[^/]*" if $mask !~ s/\$$//;
		$mask = quotemeta $mask;
		push @$re, qr!^$dir$add$mask$sub$!;
	}
	
	@$re = qr// if !@$re;
	@$dirs = $miu_dir if !@$dirs;
	
	return $dirs, $re;
}

# возвращает путь для find
sub findpath {
	my ($self, $re, $path) = @_;
	
	$path //= $File::Find::name;
	
	#$path =~ s!^\./!!;
	# если название какой-то директории с точки начинается, то в ней не смотрим
	return if $path =~ /(^|\/)\./;
	
	for my $pattern (@$re) {
		goto NEXT if $path =~ $pattern;
	}
	return;
	NEXT:
	
	return if !-f $path;
	
	$path
}

# обходит файлы и вызывает для каждого найденного функцию
sub mainfind {
	my ($self, $code) = @_;
		
	my ($dirs, $re) = $self->bypattern;
	
	my @files;
	File::Find::find({
		no_chdir => 1,
		wanted => sub {
            my $path = $self->findpath($re);
			push @files, $path if defined $path;
		}
	}, @$dirs);
	
	# сортируем
	my $pattern = $self->{pattern};
	if(@$pattern) {
        my $get_position = sub {
            my ($x) = @_;
            my $i=0;
            for my $r (@$re) {
                last if $x =~ $r;
                $i++;
            }
            $i
        };
        @files = sort { $get_position->($a) <=> $get_position->($b) } @files;
	}
	else {
        @files = sort @files;
	}
	
	for my $path (@files) {
        $code->($self, $path);
        last if $self->{stop};
	}
	
	$self
}

# обходит файлы каждую секунду
sub watch {
	my ($self, $code) = @_;
	
	my %watch;		# file => mtime
	my $watchdir = $self->{out_dir} . "/.watch";
	
	# сохраняет файл для сравнения
	my $save = sub {
		my ($path) = @_;
		$watch{$path} = -M $path;
		my $x = "$watchdir/$path";
		mkpath $x;
		output $x, input $path;
		return;
	};
	
	# разбивает файл на секции
	my $sec = sub {
		my $f = input shift;
		my @elm = split /^[=#]+[\t ]+(.+?)[\r\t ]*$/m, $f;
		my $x = {};
		for(my $i=1; $i<@elm; $i+=2) {
			$x->{$elm[$i]} = $elm[$i+1];
		}
		$x
	};
	
	# сравнивает файл и возвращает art_pattern-s
	my $diff = sub {
		my ($path) = @_;
		my $x = $sec->($path);
		my $y = $sec->("$watchdir/$path");
		local $_;
		map { qr/^[=#]+\s+${\quotemeta $_}\s*$/i } grep {$x->{$_} ne $y->{$_}} keys %$x
	};
	
	my ($dirs, $re) = $self->bypattern;
	
	while() {
		File::Find::find({
			no_chdir => 1,
			wanted => sub {
				my $path = $self->findpath($re);
				return if !defined $path;
				
				my $OLD = $watch{$path};
				
				return $save->($path) if !defined $OLD;

				if($OLD > -M $path) {
					$self->{art_pattern} = [ $diff->($path) ];
					$code->($self, $path);
					$save->($path);
				}
			}
		}, @$dirs);

		sleep 1;
		$self->{stop} = 0;
	}
	
	$self
}

# сохраняет файлы тестов
sub save {
	my $self = shift;
	
	local $_;
	
	# use Data::Dumper;
	# print STDERR Dumper($self->{codeFiles});
	
	my @codeFiles = values %{$self->{codeFiles}};
	for my $f (@codeFiles) {
		delete($self->{codeFiles}{$f->{path}}), next if !$f->{is_file_code} && $f->lines == 0;
		$f->save;
	}

	$self
}

# очищает файловые списки
sub clear {
	my $self = shift;
	
	$self->{codeFiles} = {};
	$self->{codeFile} = undef;
	
	$self
}

# возвращает драйвер языка
sub drv {
	my ($self, $lang) = @_;
	
	require "Miu/File/" . ucfirst($lang) . ".pm";
	
	"Miu::File::" . ucfirst $lang
}

# переходим на файл кода
sub tocode {
	my ($self, $path) = @_;

    if($path !~ /^\.?\//) { $path = "$self->{lib_dir}/$path"; }
    elsif($path =~ s!^./+!!) {}
	
	$self->{codeFile} = $self->{codeFiles}{$path} //= $self->drv("file")->new(path => $path, is_file_code=>1);
	
	#my $comment = $self->{defaultComment} // "#";
	#$comment = $comment x 9;
    #$self->{codeFile}->println("$comment Файл создан автоматически miu из файла $self->{path} (строка: $.)");
    
	$self
}

# переходим на тест
sub totest {
	my ($self, $lang) = @_;
	$self->{codeLang} = $lang //= $self->{codeLang} // "perl";

	my $drv = $self->drv($lang);
	my $path = $self->{test_path} . $drv->test_ext;
	
	mkpath $path;
	output $path, "";
	my $abspath = Cwd::abs_path($path);
	my $rundir = "^" . quotemeta Cwd::abs_path($self->{run_dir});
	
	
	$self->{codeFile} = $self->{codeFiles}{$path} //= $drv->new(
		path => ($abspath !~ $rundir? $abspath: $path),
		out_dir => $self->{out_dir}
	);
	
	$self
}

# переходим на инициализатор теста
sub toinit {
	my ($self) = @_;
    $self->totest;
	$self
}



# # переводит текст в bbcode
# sub markdown2bbcode {
	# my ($self, $html, $variant) = @_;
	# local $_ = $html;
	
	# # Smartypants operates first so that attributes (e.g., URLs) don't get converted
	# if (1) {
		# if (eval { require "Text/SmartyPants.pm" }) {
			# $_ = Text::SmartyPants::process($_, 2); 
		# }
		# elsif (eval { require "Text/Typography.pm" }) {
			# $_ = Text::Typography::typography($_, 2); 
		# }
	# }

	# # Simple elements
	# my %html2bb = (
		# strong     => 'b',
		# em         => 'i',
		# blockquote => 'quote',
		# hr         => 'hr',
		# u		   => 'u',
		# br         => 'br'
	# );
	# while (my($html, $bb) = each %html2bb) {
		# s{<(/|)$html[^>]*>}{[$1$bb]}g;
	# }
	
	# # Convert links
	# s{<a
		# [^>]*?       # random attributes we don't care about
		# href="(.+?)" # target
		# [^>]*?       # more random attributes we don't care about
	# >
		# (.+?)        # text
		# </a>
	# }{[url="$1"]$2\[/url]}xgi;

	# # Undo paragraphs elements
	# s{</?p>}{}g;

	# s{\[code\]}{[ code]}g;
	
	# # code
	# s{<pre><code lang="(\w+)">}      {[code=$1]}gi;
	# s{<pre><code>}      {[code=perl]}gi;
	# s{</code></pre>}    {[/code]}gi;
	
	
	# if($variant eq "LOR") {
		# # convert h1...h6
		# s{<h(\d)>}{[strong]}ig;
		# s{</h(\d)>}{[/strong]}ig;
		
		# # code inline
		# s{<code>\s*}   {[inline]}g;
		# s{\s*</code>} {[/inline]}g;
		
	# }
	# else {
		# # convert h1...h6
		# s{<h(\d)>}{"[size=" . int(100 / 6 * (6-$1) + 100) . "]"}ige;
		# s{</h(\d)>}{[/size]}ig;
		
		# # code inline
		# s{<code>\s*}   {[color=red]}g;
		# s{\s*</code>} {[/color]}g;
	# }

	

	# # списки
	# s{<ul>}     {[list]}g;
	# s{<ol>}     {[list=1]}g;
	# s{</[uo]l>} {[/list]}g;
	# s{<li>}     {[*]}g;
	# s{</li>}    {}g;


	# # Decode HTML entities
	# if(eval { require "HTML/Entities.pm" }) {
		# $_ = HTML::Entities::decode_entities($_);
	# }
	# return $_;
# }

1;

__END__

=encoding utf-8

=head1 NAME

RrruMiu - It's testing and documenting framework

=head1 SYNOPSIS

    use RrruMiu;

=head1 DESCRIPTION

See 

=head1 LICENSE

Copyright (C) dart.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

dart E<lt>darviarush@mail.ruE<gt>

=cut


