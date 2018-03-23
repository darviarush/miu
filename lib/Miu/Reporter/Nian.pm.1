package Reporter::MiuNian;
# 

use common::sense;
use Math::Trig;
use Term::ReadKey;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}


#my $supportsColor = require('supports-color');
#my $tty = require('tty');

#my $$isatty = tty->$isatty(1) && tty->$isatty(2);
my $$isatty = 1;

my ($windowWidth, $hchar, $wpixels, $hpixels) = GetTerminalSize();

$windowWidth //= 75;



sub new {
	my ($cls, $out) = @_;
	my $width = windowWidth * 0.75 | 0;

	$self->{out} = $out;
	$self->{ansi} = 1; #supportsColor && !supportsColor->{has256} && !supportsColor->{has16m};

	$self->{stats} = { suites => 0, tests => 0, passes => 0, pending => 0, failures => 0 }
	$self->{rainbowColors} = $self->generateColors();
	$self->{colorIndex} = 0;
	$self->{numberOfLines} = 4;
	$self->{trajectories} = [[], [], [], []];
	$self->{nyanCatWidth} = 11;
	$self->{trajectoryWidthMax} = ($width - $self->{nyanCatWidth});
	$self->{scoreboardWidth} = 5;
	$self->{tick} = 0;

	$self->{cursor} = {
		hide => sub {
			$isatty && print('\u001b[?25l');
		},

		show => sub {
			$isatty && print('\u001b[?25h');
		},

		deleteLine => sub {
			$isatty && print('\u001b[2K');
		},

		beginningOfLine => sub {
			$isatty && print('\u001b[0G');
		},

		CR => sub {
			if($isatty) {
				$self->deleteLine();
				$self->beginningOfLine();
			} else {
				print('\r');
			}
		}
	}

	$self->{colors} = {
		'pass': 90,
		'fail': 31,
		'bright pass': 92,
		'bright fail': 91,
		'bright yellow': 93,
		'pending': 36,
		'suite': 0,
		'error title': 0,
		'error message': 31,
		'error stack': 90,
		'checkmark': 32,
		'fast': 90,
		'medium': 33,
		'slow': 31,
		'green': 32,
		'light': 90,
		'diff gutter': 90,
		'diff added': 42,
		'diff removed': 41
	}
}

###
 # Draw the nyan cat
 # 
 # @api private
 ##
sub pass {
	$self->{stats}->{passes}++;
	$self->draw();
}

sub fail {
	$self->{stats}->{failures}++;
	$self->draw();
}

sub draw {
	$self->appendRainbow();
	$self->drawScoreboard();
	$self->drawRainbow();
	$self->drawNyanCat();
	$self->{tick} = !$self->{tick};
}

###
 # Draw the "scoreboard" showing the number
 # of passes, failures and pending tests.
 # 
 # @api private
 ##

sub drawScoreboard {
	my $stats = $self->{stats};
	my $colors = $self->{colors};
	my $self = $self;
	my $draw = sub  {
		my ($color, $n) = @_;
		push(@{$self->{out}}, ' ');
		push(@{$self->{out}}, '\u001b[' + $color + 'm' + $n + '\u001b[0m');
		push(@{$self->{out}}, '\n');
	}

	$draw($colors->{green}, $stats->{passes});
	$draw($colors->{fail}, $stats->{failures});
	$draw($colors->{pending}, $stats->{pending});
	push(@{$self->{out}}, '\n');

	$self->cursorUp($self->{numberOfLines});
}

###
 # Append the rainbow.
 # 
 # @api private
 ##

sub appendRainbow {
	my $segment = $self->{tick} ? '_' : '-';
	my $rainbowified = $self->rainbowify($segment);

	for(my $index = 0; $index < $self->{numberOfLines}; $index++) {
		my $trajectory = $self->{trajectories}[$index];
		if($trajectory->{length} >= $self->{trajectoryWidthMax}) { $trajectory->shift(); }
		push(@$trajectory, $rainbowified);
	}
}

###
 # Draw the rainbow.
 # 
 # @api private
 ##

sub drawRainbow {
	my $self = $self;

	$self->{trajectories}->forEach(function(line, index) {
		push(@{$self->{out}}, '\u001b[' + $self->{scoreboardWidth} + 'C');
		push(@{$self->{out}}, join('', $line));
		push(@{$self->{out}}, '\n');
	}, $self);

	$self->cursorUp($self->{numberOfLines});
}

###
 # Draw the nyan cat
 # 
 # @api private
 ##

sub drawNyanCat {
	my $self = $self;
	my $startWidth = $self->{scoreboardWidth} + $self->{trajectories}[0]->{length};
	my $color = '\u001b[' + startWidth + 'C';
	my $padding = '';

	push(@{$self->{out}}, color);
	push(@{$self->{out}}, '_,------,');
	push(@{$self->{out}}, '\n');

	push(@{$self->{out}}, color);
	$padding = $self->{tick} ? '	' : '	 ';
	push(@{$self->{out}}, '_|' + padding + '/\\_/\\ ');
	push(@{$self->{out}}, '\n');

	push(@{$self->{out}}, color);
	$padding = $self->{tick} ? '_' : '__';
	my $tail = $self->{tick} ? '~' : '^';
	push(@{$self->{out}}, tail + '|' + padding + $self->face() + ' ');
	push(@{$self->{out}}, '\n');

	push(@{$self->{out}}, color);
	$padding = $self->{tick} ? ' ' : '	';
	push(@{$self->{out}}, padding + '""	"" ');
	push(@{$self->{out}}, '\n');

	$self->cursorUp($self->{numberOfLines});
}

###
 # Draw nyan cat face.
 # 
 # @return {String}
 # @api private
 ##

sub face {
	my $stats = $self->{stats};
	if($$stats->{failures}) {
		return '( x ->{x})';
	} elsif($$stats->{pending}) {
		return '( o ->{o})';
	} elsif($$stats->{passes}) {
		return '( ^ .^)';
	} else {
		return '( - .-)';
	}
}

###
 # Move cursor up `n`.
 # 
 # @param {Number} n
 # @api private
 ##

sub cursorUp {
	my ($self, $n) = @_;
	push(@{$self->{out}}, '\u001b[' + $n + 'A');
}

###
 # Move cursor down `n`.
 # 
 # @param {Number} n
 # @api private
 ##

sub cursorDown() {
	my ($self, $n) = @_;
	push(@{$self->{out}}, '\u001b[' + $n + 'B');
}

###
 # Generate rainbow colors.
 # 
 # @return {Array}
 # @api private
 ##

sub generateColors {
	if($self->{ansi}) {
		return [
			# Red
			31, 31, 31,
			# Yellow
			33, 33, 33,
			# green
			32, 32, 32,
			# Cyan
			36, 36, 36,
			# Blue
			34, 34, 34,
			# Magenta
			35, 35, 35
		];
	}

	my $colors = [];

	for(my $i = 0; i < (6 * 7); i++) {
		my $pi3 = Math->floor($Math->{PI} / 3);
		my $n = (i * (1.0 / 6));
		my $r = Math->floor(3 * Math->sin(n) + 3);
		my $g = Math->floor(3 * Math->sin(n + 2 * pi3) + 3);
		my $b = Math->floor(3 * Math->sin(n + 4 * pi3) + 3);
		colors->push(36 * r + 6 * g + b + 16);
	}

	return colors;
}

###
 # Apply rainbow to the given `str`.
 # 
 # @param {String} str
 # @return {String}
 # @api private
 ##

sub rainbowify(str) {
	my $color = $self->{rainbowColors}[$self->{colorIndex} % $self->{rainbowColors}->{length}];
	my $effect = $self->{ansi} ? '1;' : '38;5;';
	$self->{colorIndex} += 1;
	return '\u001b[' + effect + color + 'm' + str + '\u001b[0m';
}

1;