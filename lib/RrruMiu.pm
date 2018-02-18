# класс
package RrruMiu;

use common::sense;
use File::Find qw//;

use EssentialMiu;

BEGIN {
	select(STDERR);	$| = 1;
	select(STDOUT); $| = 1; # default
}

sub DESTROY {
	my $self = shift;
	$self->{sd}->close if $self->{sd};
}

#msg1(":green", "✓·×");

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

	my %opt = (
		output => ".miu",
		libdir => ".miu/lib",
		bindir => ".miu",
	);

	GetOptions(
		#"p|public" => \$opt{public},
		"a|article" => \$opt{article_only},
		"t|test" => \$opt{test},
		"i|inspect:s" => \$opt{inspect},
		"l|log" => \$opt{log},
		"s|stat" => \$opt{stat},
		"o|outdir=s" => \$opt{output},
		"u|libdir=s" => \$opt{libdir},
		"b|bindir=s" => \$opt{bindir},
		"c|uncolor" => \$opt{uncolor},
		"r|reporter=s" => \$opt{reporter},
		"B|browser=s" => \$opt{browser},
		"w|watch" => \$opt{watch},
		"h|help" => \$opt{help},
	);

	# маска файлов, маска заголовков
	$opt{pattern} = [ split /:/, shift @ARGV ];
	$opt{art_pattern} = [@ARGV];

	utf8::decode($_) for @{$opt{pattern}};
	utf8::decode($_) for @{$opt{art_pattern}};
	
	build_patterns $opt{art_pattern};
	
	eval {
		require "Text/Markdown.pm";
	};
	
	%$self = (%opt, %$self);
	
	return $self;
}

# парсит и запускает тесты
sub run {
	my ($self) = @_;	
	
	if($self->{help}) {
		print "[rrru]miu [опции] [маски_файлов] [маска_разделов]...

rrrumiu компилирует файлы в код, тесты и статьи. Выполняет тесты

маски_файлов задаются через \":\"
		
ОПЦИИ
    -a, --article         не выполнять тесты: только компилировать
    -t, --test            не компилировать: выполнить тесты
    -i, --inspect[=n-k|l] тест в stdout. n - от строки, k - до строки. l - строка
    -l, --log             лог в stdout
    -s, --stat            статистику в stdout
    -o, --outdir=dir      директория для скомпиллированных тестов (.t)
    -u, --libdir=dir      директория для файлов на @@
    -b, --bindir=dir      директория для файлов кода
    -c, --uncolor         отключить цвет
    -r, --reporter=name   указать формат выдачи на консоль
	-B, --browser=command указать команду для запуска браузера ('/bin/chrome %s')
    -w, --watch           выполнять тесты из изменившейся главы
    -h, --help            эта справка
";
		exit;
	}
	
	# удаляем /
	$self->{output} =~ s!/$!!;	
		
	if(!$self->{watch}) {
		$self->find(\&prepare);
		print "Не найдено ни одного теста\n" if $self->{count_tests} == 0;
		return;
	}
	
	$self->watch(\&prepare);
}

# парсим файл и переписываем
sub prepare {
	my ($self, $path) = @_;
	
	print "$path ";
	
	$self->{path} = $path;

	$_ = $self->{output} . "/" . $path;
	
	mkpath $_;
	s/(?:\.miu)?\.\w+$//i;	# удаляем расширение
	$self->{article_path} = "$_.markdown";
	$self->{test_path} = "$_.t";
	$self->{html_path} = "$_.html";
	$self->{bbcode_path} = "$_.bbcode";
	
	$_ = $self->{bindir} . "/" . $path;
	mkpath $_;
	s/(?:\.miu)?\.\w+$//i;
	$self->{code_path} = $_;	
	
	$self->compile if !$self->{test};
	
	if(defined $self->{inspect}) {
		# Syntax::Highlight::Engine::Simple
		# 
		#`/usr/bin/env mcedit "$self->{test_path}"`;
		#if($? != 0) {
		
		my ($from, $to) = split /-/, $self->{inspect};
		
		$to //= $from;
		
		print "\n";
		open my $f, "<", $self->{test_path} or die "не открыт файл теста $self->{test_path}: $!";
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
	my $count_tests = 0;
	my $lines = $self->{lines} = {};
	my $start_code = "\n```%s\n";
	my $start_path_name = "";
	my $end_code = "```\n\n";
	
	while(<$file>) {
		
		($init, $thisIsCode, $thisIsTest) = (0,0,1), $self->totest($1), next if /^\[test(?:\s+(\w+))?\]\s*$/;
		($init, $thisIsCode, $thisIsTest) = (1,0,1), $self->toinit, next if /^\[init\]\s*$/;
        ($init, $thisIsCode, $thisIsTest) = (0,1,0), ($thisIsArticle? $start_path_name = "\@\@$1\n": push @article, "\@\@$1\n"), $self->tocode($1), next if /^\@\@(.*?)\s*$/;
        

		my $detectEmptyLine = /^\s*$/;
	
		my $thisIsHeader = s/^([=#]+)(\s+)/ ("#" x length $1) . $2 /e;
		my $level = length $1;
	
		if($thisIsHeader && $test_write) {
			my $text = $';
			my $header = $text;
			$header =~ s/\s+$//g;
			$header = ("=" x $level) . " " . $header;
			$header = $self->{codeFile}->string($header);
			
			$self->{codeFile}->header($header, $level, $text);
		}
	
		if(s/^(\t| {4})// && !$detectEmptyLine) {
			if($thisIsArticle) {
				my $i;
				for($i=$#article; $i>=0 && $article[$i] =~ /^\s*$/; $i--) {
				}
				splice @article, $i+1, 0, sprintf($start_code, $self->{codeFile}->name), $start_path_name;
				$start_path_name = "";
			}
			$thisIsArticle = 0;
		} elsif(!$detectEmptyLine) {
			push @article, $end_code if !$thisIsArticle;
			$thisIsArticle = 1;
		}
		
		push @article, $_;
        
		if(@art_pattern && $thisIsHeader) {
			for my $art_pattern (@art_pattern) {
				$test_write = $level, last if $_ =~ $art_pattern;
				$test_write = 0 if $level <= $test_write;
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
					$desc =~ s/\\[nrt]/\\$&/g;
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
		

	close $file;    # закрываем файл miu
	
    # заполняем файлы кода и тестов, очищаем codeFile и codeFiles
    $self->save;
    
	# статья-файл
	mkdir $`, 0744 while $self->{article_path} =~ m!/!g;
	open my $articleFile, ">:encoding(utf8)", $self->{article_path} or die "Не могу записать файл статьи $self->{article_path}: $!";
	print $articleFile @article;
	close $articleFile;
	
	if(exists $Text::{"Markdown::"}) {
	
		my @alines;
		my @bbcode;
		my @code;
		my $thisIsCode;
		for my $line (@article) {
			if($line =~ /\n```[a-z]\w*\n\n/i) {
				$thisIsCode = 1;
				next;
			}
			
			if($line eq $end_code) {
				push @alines, @code;
				@code = ();
				$thisIsCode = 0;
				next;
			}

			if($thisIsCode) {
				push @code, "\t$line";
			} else {
				push @alines, $line;
			}
		}
	
		my $article = join "", @alines;
		
		my $m = Text::Markdown->new;
		my $html = $m->markdown($article);
		
		# статья в формате html	
		open my $articleFile, ">:encoding(utf8)", $self->{html_path} or die "Не могу открыть файл статьи $self->{html_path}: $!";
		print $articleFile $html;
		close $articleFile;
	
		my $bbcode = $self->markdown2bbcode($html);
		
		# статья в формате bbcode
		open my $articleFile, ">:encoding(utf8)", $self->{bbcode_path} or die "Не могу открыть файл статьи $self->{bbcode_path}: $!";
		print $articleFile $bbcode;
		close $articleFile;
		
		$bbcode = $self->markdown2bbcode($html, "LOR");
		# статья в формате lorcode
		$_ = $self->{bbcode_path};
		s!\.\w+$!.lorcode!;
		open my $articleFile, ">:encoding(utf8)", $_ or die "Не могу открыть файл статьи $_: $!";
		print $articleFile $bbcode;
		close $articleFile;
		
	}
	
	
	
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
	
	my $log_path = $path;
	$log_path =~ s!\.t(\.\w+)?$!$1.log!;
	open my $log, ">", $log_path or die "Не могу открыть лог $log_path: $!";
	
	my $stat_path = $path;
	$stat_path =~ s!\.t(\.\w+)?$!$1.stat!;
	open my $stat, ">", $stat_path or die "Не могу открыть лог $stat_path: $!";

	my $current_test;
	my $current_line;
	my %ok = ();
	my %fail = ();
	my $count_tests = $self->{count_tests};
	$self->{reporter} //= "Dot";
	my $reporter = "Reporter/Miu" . ucfirst(lc $self->{reporter}) . ".pm";
	eval {require $reporter};
	print("нет обозревателя $self->{reporter}:\n$@\n"), $self->{reporter} = "dot", require "Reporter/MiuDot.pm" if $@;
	
	my $class = "Reporter::Miu" . ucfirst(lc $self->{reporter});
	
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
			
			my $result = $codeFile->parse($s, $stderr);
			
			if( $result->is_test ) {
				$current_test = $codeFile->{path} . "-" . $result->num;
				$current_line = $self->{lines}{$current_test};
				print "$current_line: " if $self->{log} || $self->{stat};
			}
			
			$reporter->report($result, $current_line) if !$self->{log} && !$self->{stat};
			
			$ok{$current_test} = $current_line if $result->is_ok;
			$fail{$current_test} = $current_line if $result->is_fail;
			
			
			# по логам
			print $stat "$result->{type} $s\n";
			print $log "$s\n";
			
			print(($self->{uncolor}? $result->{type}: colored($result->{type}, "cyan")) . " $s\n") if $self->{stat};
			print $codeFile->mapiferror($s, $self) . "\n" if $self->{log};
		};
		
		# выполняем тест-файлы в отдельных процессах. На каждую строку вывода должна запускаться $parseLine
		$codeFile->exec($self, $parseLine);		
	}
	
	close $log;
	close $stat;
	
	if(keys(%ok) == $count_tests && $count_tests != 0) {
		$reporter->ok;
	}
	else {
		$reporter->fail;
	}
	
	$self->{stop} = 1, return if keys(%ok) != $count_tests;
	
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
	
	my $dirs = [];
	my $re = [];
	
	for my $pattern (@pattern) {
		$pattern =~ s!^\./!!;
		my ($dir, $mask);
		if($pattern =~ m!(.*)/!) {
			$dir = $1;
			$mask = $';
			push @$dirs, $dir if !($dir ~~ $dirs);
			$dir = quotemeta $dir;
			$dir .= "/";
		} else {
			$dir = "";
			$mask = $pattern;
		}

		my ($add, $sub);
		$add = "[^/]*" if $mask !~ s/^\^//;
		$sub = "[^/]*" if $mask !~ s/\$$//;
		$mask = quotemeta $mask;
		push @$re, qr!^$dir$add$mask$sub$!;
	}
	
	@$re = qr// if !@$re;
	@$dirs = "." if !@$dirs;
	
	return $dirs, $re;
}

# возвращает путь для find
sub findpath {
	my ($self, $re) = @_;
	
	return if $self->{stop};
	
	my $path = $File::Find::name;
	$path =~ s!^\./!!;
	return if $path =~ /(^|\/)\.[^.\/]/;
		
	for my $pattern (@$re) {
		goto NEXT if $path =~ $pattern;
	}
	return;
	NEXT:
	
	#return if $path !~ m!\.(miu|man|human)(?:\.[^\./]+)?$!i;
	return if !-f $path;
	$path
}

# обходит файлы и вызывает для каждого найденного функцию
sub find {
	my ($self, $code) = @_;
		
	my ($dirs, $re) = $self->bypattern;
	
	File::Find::find({
		no_chdir => 1,
		wanted => sub {
			my $path = $self->findpath($re);
			return if !defined $path;
			$code->($self, $path);
		}
	}, @$dirs);
	
	$self
}

# обходит файлы каждую секунду
sub watch {
	my ($self, $code) = @_;
	
	my %watch;		# file => mtime
	my $watchdir = $self->{output} . "/.watch/";
	
	# сохраняет файл для сравнения
	my $save = sub {
		my ($path) = @_;
		$watch{$path} = -M $path;
		my $x = $watchdir . $path;
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
		my $y = $sec->($watchdir . $path);
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
	
	my $a = "Miu" . ucfirst($lang);
	require "$a.pm";
	
	$a
}

# переходим на файл кода
sub tocode {
	my ($self, $path) = @_;

    if($path !~ /^\.?\//) { $path = "$self->{libdir}/$path"; }
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
	
	$self->{codeFile} = $self->{codeFiles}{$path} //= $drv->new(path => $path, output => $self->{output});
	
	$self
}

# переходим на инициализатор теста
sub toinit {
	my ($self) = @_;
    $self->totest;
	$self
}



# переводит текст в bbcode
sub markdown2bbcode {
	my ($self, $html, $variant) = @_;
	local $_ = $html;
	
	# Smartypants operates first so that attributes (e.g., URLs) don't get converted
	if (1) {
		if (eval { require "Text/SmartyPants.pm" }) {
			$_ = Text::SmartyPants::process($_, 2); 
		}
		elsif (eval { require "Text/Typography.pm" }) {
			$_ = Text::Typography::typography($_, 2); 
		}
	}

	# Simple elements
	my %html2bb = (
		strong     => 'b',
		em         => 'i',
		blockquote => 'quote',
		hr         => 'hr',
		u		   => 'u',
		br         => 'br'
	);
	while (my($html, $bb) = each %html2bb) {
		s{<(/|)$html[^>]*>}{[$1$bb]}g;
	}
	
	# Convert links
	s{<a
		[^>]*?       # random attributes we don't care about
		href="(.+?)" # target
		[^>]*?       # more random attributes we don't care about
	>
		(.+?)        # text
		</a>
	}{[url="$1"]$2\[/url]}xgi;

	# Undo paragraphs elements
	s{</?p>}{}g;

	s{\[code\]}{[ code]}g;
	
	# code
	s{<pre><code lang="(\w+)">}      {[code=$1]}gi;
	s{<pre><code>}      {[code=perl]}gi;
	s{</code></pre>}    {[/code]}gi;
	
	
	if($variant eq "LOR") {
		# convert h1...h6
		s{<h(\d)>}{[strong]}ig;
		s{</h(\d)>}{[/strong]}ig;
		
		# code inline
		s{<code>\s*}   {[inline]}g;
		s{\s*</code>} {[/inline]}g;
		
	}
	else {
		# convert h1...h6
		s{<h(\d)>}{"[size=" . int(100 / 6 * (6-$1) + 100) . "]"}ige;
		s{</h(\d)>}{[/size]}ig;
		
		# code inline
		s{<code>\s*}   {[color=red]}g;
		s{\s*</code>} {[/color]}g;
	}

	

	# списки
	s{<ul>}     {[list]}g;
	s{<ol>}     {[list=1]}g;
	s{</[uo]l>} {[/list]}g;
	s{<li>}     {[*]}g;
	s{</li>}    {}g;


	# Decode HTML entities
	if(eval { require "HTML/Entities.pm" }) {
		$_ = HTML::Entities::decode_entities($_);
	}
	return $_;
}

1;