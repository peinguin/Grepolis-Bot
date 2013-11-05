#!/usr/bin/perl

use strict;
use warnings;

use Config::IniFiles;
use JSON;
use Email::MIME;

use Data::Dumper;

use GrepolisBotModules::Request;
use GrepolisBotModules::Town;

use utf8;

sub check_captcha{

    print "Captcha cheking \n";

    my $town_id = (keys %towns)[0];

    my $page = 'debug';
    my $action = 'log_startup_time';
    my $json = '{"t":2451,"town_id":'.$town_id.',"nlreq_id":1644995}';

    my $response_body = GrepolisBot::Request::request($page, $action, $town_id, $json, 1);

    if($response_body =~ /"type":"botcheck"/){

        open FILE, ">", $STOPFILE or die $!;
        close(FILE);

        my $message = Email::MIME->create(
          header_str => [
            From    => 'bot@php.poltava.ua',
            To      => 'pingvein@gmail.com',
            Subject => 'Captha needed!',
          ],
          attributes => {
            encoding => 'quoted-printable',
            charset  => 'ISO-8859-1',
          },
          body_str => "Grepolis Captha needed!\n",
        );

        # send the message
        use Email::Sender::Simple qw(sendmail);
        sendmail($message);

        exit;
    }
}

sub Process(\%){

    if (-e $STOPFILE) {
        exit;
    }

    check_captcha();
    
    my $url = '';
    my $page = '';
    my $action = '';
    my $town_id = '';
    my $json = '';
    my $target_id = '';
    my $retcode = 0;
    
    my($key, $value);
    while ( ($key, $value) = each(%{$_[0]}) ) {
        $town_id = $key;
        
        if($build){
            
            $page = 'building_main';
            $action = 'index';
            $json = '{"town_id":"'.$town_id.'","nlreq_id":917182}';
	        print "Build request ".$town_id."\n";
            my $response_body = GrepolisBot::Request::request($page, $action, $town_id, $json, 0);
  
            $response_body =~ m/({.*})/;

            my %hash = ( JSON->new->allow_nonref->decode( unescape($1) )->{'json'}->{'html'} =~ /BuildingMain.buildBuilding\('([^']+)',\s(\d+)\)/g );
            my $to_build = '';
            
            if(defined $hash{'main'} && $hash{'main'}<25){
                $to_build = 'main';
            }elsif(defined $hash{'academy'}){
                $to_build = 'academy';
            }elsif(defined $hash{'farm'}){
                $to_build = 'farm';
            }elsif(defined $hash{'barracks'}){
                $to_build = 'barracks';
            }elsif(defined $hash{'storage'}){
                $to_build = 'storage';
            }elsif(defined $hash{'docks'}){
                $to_build = 'docks';
            }elsif(defined $hash{'stoner'}){
                $to_build = 'stoner';
            }elsif(defined $hash{'lumber'}){
                $to_build = 'lumber';
            }elsif(defined $hash{'ironer'}){
                $to_build = 'ironer';
            }
            if($to_build ne ''){
                $action = 'build';
                $json = '{"building":"'.$to_build.'","level":5,"wnd_main":{"typeinforefid":0,"type":9},"wnd_index":1,"town_id":"'.$town_id.'","nlreq_id":'.int(rand(50000)).'}';
                my $response_body = GrepolisBot::Request::request($page, $action, $town_id, $json, 1);
                print "Build ".$to_build." ; TownId $town_id;\n";
            }
        }
        
        my ($wood_donate, $stone_donate, $iron_donate) = (0, 0, 0);
        
        if($donate_for_villages){
            $page = 'data';
            $action = 'get';
            $json = '{"types":[{"type":"map","param":{"x":15,"y":4}},{"type":"bar"},{"type":"backbone"}],"town_id":'.$town_id.',"nlreq_id":0}';
            print "Resources overflow request ".$town_id."\n";
            my $response_body = GrepolisBotModules::Request::request($page, $action, $town_id, $json, 1);

            my ($wood, $stone, $iron, $storage) = ($response_body =~ /"resources":{"wood":(\d+),"stone":(\d+),"iron":(\d+)},"storage":(\d+)/g);
            
            my $delta = 10;
            
            if($wood > $storage-$delta){
                $wood_donate += $donate;
            }
            if($stone > $storage-$delta){
                $stone_donate += $donate;
            }
            if($iron > $storage-$delta){
                $iron_donate += $donate;
            }
        }
        
        my ($k, $v);
        
        foreach $v (@{$value}){
            $target_id = $v;
            
            $page = 'farm_town_info';
            
            if($donate_for_villages && ($iron_donate > 0 || $stone_donate > 0 || $wood_donate > 0)){
                $action = 'info';
                $json = '{"id":"'.$target_id.'","town_id":"'.$town_id.'","nlreq_id":0}';
                print "Village level request. Town ID ".$town_id." Village ID ".$target_id."\n";
                my $response_body = GrepolisBotModules::Request::request($page, $action, $town_id, $json, 0);
                my ($now, $next) = ($response_body =~ /<div\sclass=\\\"farm_build_bar_amount\\\">(\d+)\\\/(\d+)<\\\/div>/g);
            
                if($now < 150000){
                    $action = 'send_resources';
                    $json = '{"target_id":'.$target_id.',"wood":'.$wood_donate.',"stone":'.$stone_donate.',"iron":'.$iron_donate.',"town_id":"'.$town_id.'","nlreq_id":251650}';
                    print "Village send request. Town ID ".$town_id." Village ID ".$target_id."\n";
                    my $response_body = GrepolisBotModules::Request::request($page, $action, $town_id, $json, 1);
                }
            }
            
            if($harvest_farms){
                my $action = 'claim_load';
                $json = '{"target_id":"'.$target_id.'","claim_type":"normal","time":300,"town_id":"'.$town_id.'","nlreq_id":917182}';
                my $response_body = GrepolisBotModules::Request::request($page, $action, $town_id, $json, 1);
                print "Farm get harvest. TownId $town_id farmId $target_id \n";
            }
        }
    }
}

my $Towns = [];

sub StartGame{
    my $game = GrepolisBotModules::Request::base_request('http://en68.grepolis.com/game');
    $game =~ /"townId":(\d+),/;
    push($Towns, new GrepolisBotModules::Town($1));
}

StartGame();