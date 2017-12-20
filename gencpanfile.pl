BEGIN { push  @INC, "." }



$r{$_} = 1, require $_ for split /\s+/, `echo lib/*.pm`;

for my $package (keys %INC) {
	next if exists $r{$package} or $package =~ m!File/Spec/!;

	$package =~ s{/}{::}g;
	$package =~ s/.pm$//;
	my $version = eval "$package->VERSION";

	$version =~ s/_.*$//;

	$modules{ $package } = $version;
}

for (sort keys %modules) {
	my $version = $modules{$_};

	print "requires '$_';";
	print " # == $version" if $version;
	print "\n";
}