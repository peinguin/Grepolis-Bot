#!/usr/bin/perl

use strict;
use warnings;

use Config::IniFiles;

use GrepolisBotModules::Request;
use GrepolisBotModules::Town;
use GrepolisBotModules::Async;
use GrepolisBotModules::Log;

use utf8;

my $cfg = Config::IniFiles->new( -file => "config.ini" );
my $config = {
    security => {
        sid    => $cfg->val( 'security', 'sid' ),
        server => $cfg->val( 'security', 'server' )
    },
    global => {
        log    => $cfg->val( 'global', 'log' ),
    }
};
undef $cfg;

my $Towns = [];

GrepolisBotModules::Async::run sub{

    GrepolisBotModules::Request::init($config->{'security'});
    GrepolisBotModules::Log::init($config->{'global'});

    GrepolisBotModules::Log::echo(0, "Program started\n");

    my $game = GrepolisBotModules::Request::base_request('http://en68.grepolis.com/game');

    $game =~ /"csrfToken":"([^"]+)",/;
    GrepolisBotModules::Request::setH($1);
    $game =~ /"townId":(\d+),/;
    GrepolisBotModules::Log::echo 1, "Town $1 added\n";
    push($Towns, new GrepolisBotModules::Town($1));
};