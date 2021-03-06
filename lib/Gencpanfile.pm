package Gencpanfile;
# генерирует cpanfile

use common::sense;

# добавляет либы
sub lib {
	my ($self, @libs) = @_;
	
	push  @INC, @libs;
	
	$self
}

# генерирует cpanfile
sub gen {
	my ($self) = @_;

	my %modules;
	my %r;
	$r{$_} = 1, require $_ for grep { s/lib\/// } split /\s+/, `find lib -name '*.pm'`;

	for my $package (keys %INC) {
		next if exists $r{$package} or $package =~ m!File/Spec/!;

		$package =~ s{/}{::}g;
		$package =~ s/.pm$//;
		my $version = eval "$package->VERSION";

		$version =~ s/_.*$//;

		$modules{ $package } = $version;
	}

	# for(split /\s+/, `find lib -name '*.pm'`) {
		# open f, $_ or die $!;
		# read f, $_, -s f;
		# close f;
		
		# $pkg{$1}=1 while m!\buse\s+([a-zA-Z_]\w*(?:::[a-zA-Z_]\w*))|require\s*""|!g;
	# } 

	
	
	for (sort keys %modules) {
		my $version = $modules{$_};
		print "requires '$_';";
		print " # == $version" if $version;
		print "\n";
	}
	
	
	
}

1;