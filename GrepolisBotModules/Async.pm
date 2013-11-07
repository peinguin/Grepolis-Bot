package GrepolisBotModules::Async;

use GrepolisBotModules::Log;

use IO::Async::Timer::Countdown;
use IO::Async::Loop;

my $loop = IO::Async::Loop->new;

sub delay{
	my($delay, $callback) = @_;

	GrepolisBotModules::Log::echo 1, "Start delay $delay \n";

	my $timer = IO::Async::Timer::Countdown->new(
		delay => $delay,
		on_expire => $callback,
	);
	 
	$timer->start;
	$loop->add( $timer );
}

sub run{
	$loop->later(shift);
	$loop->run;
}

1;