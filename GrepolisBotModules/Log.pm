package GrepolisBotModules::Log;

use Data::Dumper;
use POSIX;

my $log_type = undef;

sub echo{
	$type = shift;
	$text = shift;
	if($type >= $log_type){
		print POSIX::strftime("%Y-%m-%d %H:%M:%S ", localtime);
		print $text;
	}
}

sub dump{
	echo shift, Dumper(shift);
}

sub init{
	my $config = shift;
	$log_type = int($config->{'log'});
}

1;