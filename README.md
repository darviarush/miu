# miu - система одновременного кодирования, документирования и тестирования

## Что такое miu

В одном файле miu можно набрать статью, в нём же - код и тесты к нему, а потом протестировать код и создать документацию, набрав всего лишь одну команду **miu**.

## Быстрый старт

miu считает любой текст примыкающий к началу строки текстом статьи, а с отступом - кодом.

```perl

my $abs = 16;	# 16

```

теперь я запущу команду

```perl

`miu 0x` # 0x-miu.miu.pl ...\n

```

файл этой статьи назвается у меня **miu/0x-miu.miu**. Он будет выполнен, как тест. Точки - это успешно пройденные тесты. **E** - не пройденные. **F** - которые умерли через die.
Точки соответствуют строкам кода с **#**.
Выполняются все файлы начинающиеся на 0x. 

То что стоит после **#** считается строкой для сравнения без начальных и концевых пробелов. Если нам нужно сравнить с выражением perl, то ставим **##**. Сравните:

```perl

1+5 # 6
1+5 ## 1+5
" 26\n" # \s26\n
bless {a=>2}, "Class" ## bless {a=>2}, "Class"

```

Львиная доля тестов приходится как раз на умное сравнение (обратите внимание на последний тест). Однако иногда мне бы хотелось сказать "больше" или "меньше".

```perl

2**3 #< 10
8 #!= 3
"8" #== 8
"meat" #ne eat
"abc" ##lt "eat"
"test" #~ es.$
{} #!~ (?i)^array
123456 #startswith 123
123456 #endswith 456

```

Если тест бросает исключение, то его можно протестировать так:

```perl

die "myexception" #@ startswith myexception
die "myexception" ##@ !~ qr/чего\?/
die "myexception" #@ !~ чего\?

```

Тестируем поток вывода:

```perl

print "123\n" #>> 123\n

```

А поток ошибок:

```perl

print STDERR " +26\t\r\e\v" #&> \s+26\t\r\e\v

```

**#!** тестирует переменную ошибок ввода-вывода $!

```perl

open $f, "/"; ##! ""

```

## Программный код

Код программы так же может быть записан в файл miu. Он так же должен иметь отступ.
Чтобы переключатся между кодом и тестом нужно использовать `[code]` и `[test]` с начала строки.

**[code]**

```perl

package A::A;

sub A { print "A" }

1;

```

**[test]**

```perl

use A::A;
&A::A::A; #>> A

```

**[code]**

```perl

package main;
use A::A;
&A::A::A;

```

**[test]**

```perl

`.miu/00-miu` # A

```

Каждая строка **package** будет генерировать файл **.miu/lib/A/A.pm** и он будет подключён к тесту.

Изменить путь к каталогу **lib** можно ключём -u path/to/mylib.  
А к каталогу с кодом программы: -b path/to/myexecutefile


## Как выполнить тесты из раздела статьи

Часто пишешь-пишешь, написал огромную статью, тесты все в ней запускать - не хочется. Нужно запустить какой-то, над которым работаешь.

```perl

`miu 0x "метки"` # 0x-miu.miu.pl .\n

```

Выполнятся все тесты в разделе название которого начинается на ***метки*** или ***Метки*** - сравнение регистронезависимое.

**== Метки 1**

В статье 0x-miu.miu.pl это раздел ***Метки 1***.
Если таких разделов два, то выполнятся оба. Несколько - несколько.

## Какие файлы создаёт miu

miu ищет файлы в текущей директории. Хотя в маске можно указать путь к файлам.

```perl

`cd ..; miu miu/0x -o miu/.miu` # miu/0x-miu.miu.pl ...\n

```

После запуска miu создат выходной каталог __.miu__ в текущей директории.  
Вы можете использовать ключ -o, чтобы изменить его.

4. **.miu/название_файла.markdown**
3. **.miu/название_файла.t**
1. **.miu/название_файла.log**
2. **.miu/название_файла.stat**
5. **.miu\miu-tmp-fh**


1. *.markdown - это документация на языке markdown. То есть, это копия файла miu\название_файла.miu, без тегов `[test]` и `[code]`
2. *.t - это тест
3. *.log - это вывод теста
5. *.stat - то же что и *.log, только с названиями токенов
6. **miu-tmp-fh** - вспомогательный файл для тестирования ввода-вывода (#>> и #&>)


Эти файлы перезаписываются после каждого теста.

```perl

-e ".miu/0x-miu.log" # 1

```

Можно сразу вывести ошибки на консоль:

```perl

`miu -l 0x` #~ \.*

```

После первой же ошибки остальные файлы не выполнятся.

## Установка

**miu** выложена на github и bitbucket:

1. https://github.com/darviarush/miu
2. https://bitbucket.org/darij/miu 

Установить через git:

1. git clone git@github.com:darviarush/miu.git
2. git clone git@bitbucket.org:darij/miu.git 

Далее выполните `make link`, эта команда создаст символьную ссылку на исполняемый файл miu в директории **/bin/**.


## Откуда название **miu**?

miu названа в честь Рррумиу - героини романа Павла Шумила "Этот мир придуман не нами" из цикла "Окно контакта - 3".

## TODO или куда miu будет развиваться

Что ещё предстоит сделать:

1. Поддержка других языков программирования - сейчас поддерживается только **perl**
3. Конвертеры из markdown в другие языки размётки: html, bbcode, wiki и т.д.
2. Автоматическая публикация получившихся статей на различных сайтах. Например, на habrahabr.ru, linux.org.ru, livejournal.com, wikipedia.org и т.д.

