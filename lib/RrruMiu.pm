# класс
package RrruMiu;

use common::sense;
use File::Find qw//;

# конструктор
sub new {
	my ($cls, $opt) = @_;
	bless {%$opt}, $cls
}

# парсит и запускает тесты
sub run {
	my ($self) = @_;	
	
	if($self->{help}) {
# -p, --public       опубликовать в интернте, см. etc/miu.sample.ini
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
    -h, --help            эта справка
";
		exit;
	}
	
	mkdir $self->{output} unless -e $self->{output};
	
	# удаляем /
	$self->{input} =~ s!/$!!;
	$self->{output} =~ s!/$!!;	
	
	$self->{log} = 1 if $self->{stat};
	
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
		
	});
	
	print "Не найдено ни одного теста\n" if $self->{count_tests} == 0;
	
}


# разбивает файл на 3 части: код, тест и документацию
sub compile {
	my ($self) = @_;
	
    # открываем файл
	my $path = $self->{path};
	open my $file, "<:encoding(utf8)", $path or die "Не могу открыть файл miu $path: $!";
		
    # чистим переменные
    $self->clear->totest;
        
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
	my $start_code = "\n```perl\n";
	my $start_path_name = "";
	my $end_code = "```\n\n";
	
	while(<$file>) {
		
		($init, $thisIsCode, $thisIsTest) = (0,0,1), $self->totest, next if /^\[test\]\s*$/;
		($init, $thisIsCode, $thisIsTest) = (1,0,1), $self->toinit, next if /^\[init\]\s*$/;
        ($init, $thisIsCode, $thisIsTest) = (0,1,0), ($thisIsArticle? $start_path_name = "\@\@$1\n": push @article, "\@\@$1\n"), $self->tocode($1), next if /^\@\@(.*?)\s*$/;
        

		my $detectEmptyLine = /^\s*$/;
	
		my $thisIsHeader = s/^([=#]+)(\s+)/ ("#" x length $1) . $2 /e;
		my $len_last = length($1) + length $2;
	
		if($thisIsHeader && $test_write) {
			my $text = ("=" x length $1) . $2 . $';
            $text =~ s/\s+$//g;
			$text =~ s/'/\\'/g;
			$self->println("print STDERR '$text' . \"\\n\";");
		}
	
		if(s/^(\t| {4})// && !$detectEmptyLine) {
			if($thisIsArticle) {
				my $i;
				for($i=$#article; $i>=0 && $article[$i] =~ /^\s*$/; $i--) {
				}
				splice @article, $i+1, 0, $start_code, $start_path_name;
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
                $self->println($_);
			}
			
			###################### [test]
			elsif($thisIsTest && ($test_write || $init)) {
				
				my $replace = sub {
					$count_tests ++;
					
					push @$lines, $.;
					
					my ($start, $code, $who, $op, $op2, $end) = ($1, $2, $3, $4, $5, $6);
					
					$op //= $op2;
					
					$end =~ s/^\s*(.*?)\s*$/$1/;	# избавляемся от начальных и конечных пробелов
										
					if(!$code) {
					
						if($op eq "~" or $op eq "!~") {
							$end = "qr{$end}";
						} else {
							$end =~ s/["\@\$]/\\$&/g;
							$end =~ s/\\s/ /g;
							$end = "\"$end\"";
						}
						
					}
					else {
						$end =~ s/;$//;
						$end = "scalar($end)";
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
                        $begin = "___std(\\*STDOUT); $start; ___res(\\*STDOUT); ";
						$start = "___get()";
					}
					elsif($who eq "&>") {	#STDERR
                        $begin = "___std(\\*STDERR); $start; ___res(\\*STDERR); ";
						$start = "___get()";
					}
					elsif($who eq "\@") {
                        $begin = "eval { $start }; ";
						$start = "\$@";
					}
					elsif($who eq "!") {
                        $begin = "$start; ";
						$start = "\$!";
					}
					
					$start = "scalar($start)";

					my $desc = $_;
					$desc =~ s/\s*$//;
					$desc =~ s/'/\\'/g;
					$desc = "'$desc'";
					
                    $begin . do {
                        if(!$op && !$code) {
                            "is( $start, $end, $desc );";
                        } elsif(!$op) {
                            "is_deeply( $start, $end, $desc );";
                        } elsif($op eq "startswith") {
                            "is( substr($start, 0, length(\$_ret = $end)), \$_ret, $desc );";
                        } elsif($op eq "endswith") {
                            "is( substr($start, -length(\$_ret = $end)), \$_ret, $desc );";
                        } elsif($op eq "~") {
                            "like( $start, $end, $desc );"
                        } elsif($op eq "!~") {
                            "unlike( $start, $end, $desc );"
                        } else {
                            "cmp_ok( $start, '$op', $end, $desc );";
                        }
                    };
					
				};
				
				my $oper = "gt|lt|ne|eq|le|ge|==|!=|>|<|<=|>=|~|!~|startswith|endswith";
				if(/^\s*#/) {}
				elsif( s/^\s*(.*?);*[ \t]+#(#)?(?:(\@|!|>>|&>)(?:[ \t]+($oper))?|($oper))?[ \t](.*?)$/$replace->()/eo ) {}
				
                $self->println($_);
                
			}
			
		}
		
	}
		

    # дополняем тест
	my $output = $self->{output};
	$output =~ s![\"]!\\$&!g;
	
	$self->unshift_test('#!/usr/bin/env perl
# сгенерировано miu

use utf8;
	
use open ":std", ":encoding(utf8)";
use Test::More tests => ' . $count_tests . ';

my ($_f, $_ret);

sub ___std {
my $fh = shift;
open $_f, ">&", $fh; close $fh; open $fh, ">", "' . $output . '/miu-tmp-fh";
}

sub ___res {
my $fh = shift;
close $fh;
open $fh, ">&", $_f;
}

sub ___get {
open my $f, "' . $output . '/miu-tmp-fh";
read $f, my $buf, -s $f;
close $f;
$buf
}

');

        
        
	close $file;    # закрываем файл miu
	
  	# создаём тест-файл
	mkdir $`, 0744 while $self->{test_path} =~ m!/!g;
	open my $testFile, ">:encoding(utf8)", $self->{test_path} or die "Не могу записать файл теста $self->{test_path}: $!";
    $self->{codeFiles}{$self->{test_path}} = $testFile;

    
    # заполняем файлы кода
    my $files = $self->{codeFiles};
    my $codes = $self->{codefile};
    while(my ($path, $f) = each %$files) {
        print $f join "\n", @{$codes->{$path}};
        close $f;
    }
    
    
	

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
			if($line eq $start_code) {
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
use TAP::Parser;
sub test {
	my ($self) = @_;
	
	my $path = $self->{test_path};
	
	#for my $path (@{$self->{test_path}}) {
	#print "$path ";
	
	my $log_path = $path;
	$log_path =~ s!\.\w+$!.log!;
	open my $log, ">", $log_path or die "Не могу открыть лог $log_path: $!";
	
	my $stat_path = $path;
	$stat_path =~ s!\.\w+$!.stat!;
	open my $stat, ">", $stat_path or die "Не могу открыть лог $stat_path: $!";
	
	my $parser = TAP::Parser->new( {
		source => $path,
		merge => 1,
		switches => [ '-I' . $self->{libdir} ],
	} );
	
    my $smap = $self->{map};
    my $miu_path = $self->{path};    
    
    my $map = sub {
        my ($s) = @_;
        my $lineno;
        #print "`$s`\n\n";
        #print m{at (.*?) line (\d+)}."==\n";
        my $run = sub {
            print "at $1 line $2\n";
            if(exists $smap->{$1} and $lineno = $smap->{$1}[$2-1]) { "$& (AKA $lineno IN $miu_path)" }
            else {$&}
        };
        $s =~ s{at (.*?) line (\d+)}{$run->()}ge;
        
        $s
    };
    
	my $was_fail = 0; # сброс F
	my @errors; # эксепшены
	my @fail;	# непройденные тесты
	my @FAIL;
	my @ERRORS;
	my $first;	# первый фейл или ошибка
	my $count_ok = 0; # количество пройденных тестов
	my ($count_pass, $count_tests);	# количество файлов-тестов (1) и количество всех тестов
	my $current_test;
	my $current_line = 0;
	
	while ( my $result = $parser->next ) {
		
		######### логика
		
		if( $result->is_comment ) {
			$first = 2 if !$first;
			push @fail, $result->raw;
		} elsif(@fail) {
			push @FAIL, [$current_line, join("\n", @fail)];
			@fail = ();
		}
		
		if( $result->is_unknown ) {
		
			if($result->raw !~ /^=/) {
				push @errors, $result->raw;
				$first = 1 if !$first;
				
				if(!$was_fail) {
					print "F" if !$self->{log};
					$was_fail = 1;
				}
			}
		} else {
			$was_fail = 0;
			
			if(@errors) {
				push @ERRORS, [$current_line, join("\n", @errors)];
				@errors = ();
			}
			
		}

		if( $result->is_plan ) {
			($count_pass, $count_tests) = split /\.\./, $result->raw;
		}
		
		
		if( $result->is_test ) {
			if( $result->is_ok ) {
				print "." if !$self->{log};
				$count_ok++;
			} else {
				print "E" if !$self->{log};
			}
			
			($current_test) = $result->raw =~ /(\d+)/;
			
			$current_line = $self->{lines}[$current_test];
			
			
			print "$current_line: " if $self->{log};
		}
		
		
		######### статистика
		my @stat;
		
		if( $result->is_plan ) {
			push @stat, "is_plan ";
		}
		if( $result->is_pragma ) {
			push @stat, "is_pragma ";
		}
		if( $result->is_test ) {
			push @stat, "is_test ";
		}
		if( $result->is_comment ) {
			push @stat, "is_comment ";
		}
		if( $result->is_bailout ) {
			push @stat, "is_bailout ";
		}
		if( $result->is_version ) {
			push @stat, "is_version ";
		}
		if( $result->is_unknown ) {
			push @stat, "is_unknown ";
		}
		if( $result->is_yaml ) {
			push @stat, "is_yaml ";
		}
		if( $result->has_directive ) {
			push @stat, "has_directive ";
		}
		if( $result->has_todo ) {
			push @stat, "has_todo ";
		}
		if( $result->has_skip ) {
			push @stat, "has_skip ";
		}
	
		# по логам
		print $stat @stat if @stat;
		print $stat $result->as_string . "\n";
		print $log $result->as_string . "\n";
		
		print @stat if $self->{stat};
		print $map->($result->as_string) . "\n" if $self->{log};
	} 

	push @FAIL, [$current_line, join("\n", @fail)] if @fail;
	push @ERRORS, [$current_line, join("\n", @errors)] if @errors;
	
	close $log;
	close $stat;

	if($count_ok == $count_tests) {
		print " ok\n";
	}
	else {
		print " fail\n";
	}
	
	
	
	######### сохраняем фейлы и ошибки
	$self->{fail} = [@FAIL];
	$self->{errors} = [@ERRORS];
	
	#use Data::Dumper; print Dumper(\@FAIL, \@ERRORS);
	
	######### первая ошибка
	if(@ERRORS) {
		$_ = $ERRORS[0][1];
		if( m!\bat (.*?) line (\d+)\.! ) {
			$self->{first_error} = $` . $&;
		} else {
			$self->{first_error} = $_;
		}
	}
	
	######### обрезаем последнюю строку со статусом
	if(@FAIL) {
		@fail = split /\n/, $FAIL[$#FAIL][1];
		$self->{test_status} = pop @fail;
		$FAIL[$#FAIL][1] = join "\n", @fail;
		pop @FAIL if $FAIL[$#FAIL][1] eq "";
	}
	
	if(!$self->{log}) {
		if(@ERRORS && !@FAIL) {	# @ERRORS && $first == 1
			print $map->($self->{first_error});
			print "\nпосле строки № $ERRORS[0][0]\n";
		}
		
		if(@FAIL) {	# (@FAIL && $first == 2)
			print $map->($FAIL[0][1]);
			print "\nна строке № $FAIL[0][0]\n";
		}

	}
	
	$count_ok == $count_tests;
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


# очищает файловые списки
sub clear {
	my ($self) = @_;
    
    $self->{codeFiles} = {};
    $self->{codePath} = undef;
    $self->{codefile} = {};
    $self->{map} = {};    
	$self
}


# создаёт файл кода
sub tocode {
	my ($self, $path) = @_;

    if($path !~ /^\.?\//) { $path = "$self->{libdir}/$path"; }
    elsif($path =~ s!^./+!!) {}
    
    $self->{codePath} = $path, return if exists $self->{codefile}{$path};
     
    if(!-e $path) {
        # создаём директории
        mkdir $` while $path =~ m!/!g;
    }
    
    open my $codeFile, ">", $path or die "Не могу открыть файл кода $path: $!";
    
    $self->{codeFiles}{$path} = $codeFile;
	$self->{codePath} = $path;
    
    $self->println("######### Файл создан автоматически miu из файла $self->{path} (строка: $.)");
    
	$self
}

# переходим на тест
sub totest {
	my ($self) = @_;
    $self->{codePath} = $self->{test_path};
	$self
}

# переходим на инициализатор теста
sub toinit {
	my ($self) = @_;
    $self->totest;
	$self
}

# печатает в текущий файл кода
sub println {
	my ($self, $s) = @_;
    
	my $path = $self->{codePath};
    
    die "println: нет пути файла" if !defined $path;
    die "println: неожиданный перевод строки" if $s =~ /\n/;
    
	push @{$self->{codefile}{$path}}, $s;
    
    # маппинг строк файла в файле miu
	push @{$self->{map}{$path}}, $.;
	
	$self
}

# добавляет заголовок теста
sub unshift_test {
	my ($self, $s) = @_;
    
    my @lines = split /\n/, $s;
    unshift @{$self->{codefile}{$self->{test_path}}}, @lines;
    
    # меняем маппинг
    my $map = $self->{map}{$self->{test_path}};
    my $fill = $map->[0];
    
    unshift @$map, ($fill) x @lines;
    
 
    
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