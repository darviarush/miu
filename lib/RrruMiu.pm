# класс
package RrruMiu;

use common::sense;
use File::Find qw//;

use EssentialMiu;

BEGIN {
	select(STDERR);	$| = 1;
	select(STDOUT); $| = 1; # default
}

#msg1(":green", "✓·×");

# конструктор
sub new {
	my $cls = shift;
	bless {
		@_,
		lang => {},			# драйверы языков программирования
	}, $cls
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
		"h|help" => \$opt{help},
	);

	# маска файлов, маска заголовков
	$opt{pattern} = [ split /:/, shift @ARGV ];
	$opt{art_pattern} = [@ARGV];

	utf8::decode($_) for @{$opt{pattern}};
	utf8::decode($_) for @{$opt{art_pattern}};

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
    -o, --outdir=dir      директория для скомпиллированных файлов
    -u, --libdir=dir      директория для пакетов perl
    -b, --bindir=dir      директория для файлов кода
    -c, --uncolor         отключить цвет
    -h, --help            эта справка
";
		exit;
	}
	
	mkdir $self->{output} unless -e $self->{output};
	
	# удаляем /
	$self->{input} =~ s!/$!!;
	$self->{output} =~ s!/$!!;	
	
	#$self->{log} = 1 if $self->{stat};
	
	my $count = 0;
	
	# парсим файл и переписываем
	$self->find(sub {
		my ($path) = @_;
		
		$count++;
		
		print "$path ";
		
		$self->{path} = $path;
		
		my $sub = substr $path, length $self->{input};
		$sub =~ s!^/!!;
	
		$_ = $self->{output} . "/" . $sub;
		s/(?:\.miu)?\.\w+$//i;	# удаляем расширение
		$self->{article_path} = "$_.markdown";
		$self->{test_path} = "$_.t";
		$self->{html_path} = "$_.html";
		$self->{bbcode_path} = "$_.bbcode";
		
		$_ = $self->{bindir} . "/" . $sub;
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
				exit 1 if !$self->test;
			}
			
		}
		
		$self->clear;
		
	});
	
	print "Не найдено ни одного теста\n" if $self->{count_tests} == 0;
	
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
	my $lines = $self->{lines} = [1];
	my $start_code = "\n```%s\n";
	my $start_path_name = "";
	my $end_code = "```\n\n";
	
	while(<$file>) {
		
		($init, $thisIsCode, $thisIsTest) = (0,0,1), $self->totest($1), next if /^\[test(?:[\t ]+(\w+))?\]\s*$/;
		($init, $thisIsCode, $thisIsTest) = (1,0,1), $self->toinit, next if /^\[init\]\s*$/;
        ($init, $thisIsCode, $thisIsTest) = (0,1,0), ($thisIsArticle? $start_path_name = "\@\@$1\n": push @article, "\@\@$1\n"), $self->tocode($1), next if /^\@\@(.*?)\s*$/;
        

		my $detectEmptyLine = /^\s*$/;
	
		my $thisIsHeader = s/^([=#]+)(\s+)/ ("#" x length $1) . $2 /e;
		my $len_last = length($1) + length $2;
	
		if($thisIsHeader && $test_write) {
			my $level = length $1;
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
			my $last = substr $_, $len_last, length $_;
		
			my $level = length $1;
			
			for my $art_pattern (@art_pattern) {
				my $art_len = length($art_pattern);
				
				if(uc($art_pattern) eq uc substr $last, 0, $art_len) {
					$test_write = $level;
					last;
				}
				elsif($level <= $test_write) {
					$test_write = 0;
				}
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
				elsif( /^\s*(.*?);*[ \t]+$comment(#)?(?:(\@|!|>>|&>)(?:[ \t]+($oper))?|($oper))?[ \t](.*?)$/ ) {
					$self->{codeFile}->count_tests(++$count_tests);
					
					push @$lines, $.;
					
					my ($start, $code, $who, $op, $op2, $end) = ($1, $2, $3, $4, $5, $6);
					
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
    $self->save(count_tests => $count_tests, output => $self->{output});
    
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

	for my $codeFile (@tests) {
		my $path = $codeFile->{path};
	
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
		my $count_tests = $codeFile->{count_tests};
		
		use Reporter::MiuDot;
		my $reporter = Reporter::MiuDot->new(
			uncolor=>$self->{uncolor}, 
			count_tests=>$count_tests,
			lines => $self->{lines},
			ok => \%ok,
			fail => \%fail,
			path => $self->{path},
		);
		print $reporter->start;
		
		my $parseLine = sub {
			my ($s, $stderr) = @_;
			
			######### логика
			
			my $result = $codeFile->parse($s, $stderr);
			
			if( $result->is_test ) {
				$current_test = $result->num;
				$current_line = $self->{lines}[$current_test];
				print "$current_line: " if $self->{log} || $self->{stat};
			}
			
			my $out = $reporter->report($result, $current_line);
			print $out if !$self->{log} && !$self->{stat};
			
			$ok{$current_test} = $current_line if $result->is_ok;
			$fail{$current_test} = $current_line if $result->is_fail;
			
			
			# по логам
			print $stat "$result->{type} $s\n";
			print $log "$s\n";
			
			print(($self->{uncolor}? $result->{type}: colored($result->{type}, "cyan")) . " $s\n") if $self->{stat};
			print $codeFile->mapiferror($s, $self) . "\n" if $self->{log};
		};
		
		### open3 simple
		use IPC::Open3::Simple;
		my $ipc = IPC::Open3::Simple->new(out=>sub{$parseLine->($_[0], 0)}, err=>sub{$parseLine->($_[0], 1)});
		$ipc->run($codeFile->exec($self));
		
		# ### open3 callback
		# my $stdout = [];
		# my $stderr = [];
		# my $cb = sub {
			# my ($chunk, $std) = @_;
			# while($chunk =~ /(.*)(?:\r\n|\n|\r)/g) {
				# push @$std, $1;
				# $parseLine->(join("", @$std), $std == $stderr);
				# @$std = ();
			# }
			# push @$std, $1 if $chunk =~ /([^\r\n]+)\z/g;
		# };
		
		# $Log::Log4perl::Logger::NON_INIT_WARNED=1;	# Log::Log4perl использует IPC::Open3::Callback
		
		# use IPC::Open3::Callback;
		# my $ipc = IPC::Open3::Callback->new({
			# out_callback => sub { $cb->($_[0], $stdout) }, 
			# err_callback => sub { $cb->($_[0], $stderr) }
		# });
		# $ipc->run_command($codeFile->exec($self));
		
				
		close $log;
		close $stat;
		
		if(keys(%ok) == $count_tests && $count_tests != 0) {
			print $reporter->ok;
		}
		else {
			print $reporter->fail;
		}
		
		return if keys(%ok) != $count_tests;
	}
	return 1;
}


# публикует в интернете: хабре и т.д.
sub post {
	my ($self) = @_;
	$self
}


# обходит файлы и вызывает для каждого найденного функцию
sub find {
	my ($self, $code) = @_;
		
	my @pattern = @{$self->{pattern}};
	@pattern = "" if !@pattern;
	
	for my $pattern (@pattern) {
	
		$pattern =~ s!^\./!!;
	
		my $len = length $pattern;
		my ($path) = $pattern =~ m!(.*)/!;
		$self->{input} = $path;
		
		File::Find::find({
			no_chdir => 1,
			wanted => sub {
				my $path = $File::Find::name;
				$path =~ s!^\./!!;
				return if $pattern ne substr $path, 0, $len;
				#return if $path !~ m!\.(miu|man|human)(?:\.[^\./]+)?$!i;
				return if !-f $path;

				$code->($path);
			}
		}, $path || ".");
		
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
		$f->options(@_)->save;
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
	
	$self->{codeFile} = $self->{codeFiles}{$path} //= $drv->new(path => $path);
	
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