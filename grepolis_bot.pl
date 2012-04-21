#!/usr/bin/perl

use strict;
use warnings;
use WWW::Curl::Easy;
use URI::Escape;
use Config::IniFiles;
use Data::Dumper;
use Unicode::Escape qw(escape unescape);
use URI::Encode qw(uri_encode uri_decode);
use JSON;

my $cfg = Config::IniFiles->new( -file => "config.ini" );

my $sid = $cfg->val( 'security', 'sid' );
my $h = $cfg->val( 'security', 'h' );
my $server = $cfg->val( 'security', 'server' );

my %towns = ();

foreach my $town ($cfg->Parameters('towns')){
    my @villagies = split(', ',$cfg->val( 'towns', $town ));
    $towns{$town} = \@villagies;
}
my @cookies = (
    '__utma=1.186868278.1328023865.1328092768.1328172347.3',
    '__utmz=1.1328092768.2.2.utmcsr=ru.grepolis.com|utmccn=(referral)|utmcmd=referral|utmcct=/start',
    'cid=1514937687',
    'PHPSESSID=66heoqi60jquur1005c5pm6uu0',
    'sid='.$sid,
    'logged_in=true',
    '__utmc=1',
    '__utmb=1.25.9.1328172446000',
    'fbm_227823082573=base_domain=.grepolis.com',
    'fbsr_227823082573=Y896psH56np92p6Kf_HuRhYdS16R8FiuA4jRRYI8eqU.eyJhbGdvcml0aG0iOiJITUFDLVNIQTI1NiIsImNvZGUiOiIyLkFRRHJKM2l2N0wxWHgzMnQuMzYwMC4xMzI4MTc2ODAwLjEtNjc1MDYzODc1fDZ3SE8yTnZRdVh2d1hBUFBsSGZNMnF5eENqWSIsImlzc3VlZF9hdCI6MTMyODE3MjM2NywidXNlcl9pZCI6IjY3NTA2Mzg3NSJ9',
);

my @headers = ('Accept:	text/plain, */*; q=0.01');
push(@headers, 'Accept-Charset:	ISO-8859-1,utf-8;q=0.7,*;q=0.7');
push(@headers, 'Accept-Encoding:');
push(@headers, 'Accept-Language: en-us,en;q=0.5');
push(@headers, 'Cache-Control: no-cache');
push(@headers, 'Connection:	keep-alive');
push(@headers, 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8');
push(@headers, 'Cookie: '.join('; ', @cookies));
push(@headers, 'Host: ru8.grepolis.com');
push(@headers, 'Pragma:	no-cache');
push(@headers, 'Referer: http://ru8.grepolis.com/game/index?login=1');
push(@headers, 'User-Agent:	Mozilla/5.0 (X11; Linux x86_64; rv:9.0.1) Gecko/20100101 Firefox/9.0.1 Iceweasel/9.0.1');
push(@headers, 'X-Requested-With: XMLHttpRequest');

my $curl = WWW::Curl::Easy->new;
$curl->setopt(CURLOPT_HEADER,0);
$curl->setopt(CURLOPT_HTTPHEADER, \@headers);

my $harvest_chiken = $cfg->val( 'options', 'harvest_chiken' );
my $build = $cfg->val( 'options', 'build' );
my $harvest_farms = $cfg->val( 'options', 'harvest_farms' );

sub Process(\%){
    
    my $url = '';
    my $page = 'farm_town_info';
    my $action = 'claim_load';
    my $town_id = '';
    my $json = '';
    my $target_id = '';
    my $retcode = 0;
    
    my($key, $value);
    while ( ($key, $value) = each(%{$_[0]}) ) {
        $town_id = $key;
        my ($k, $v);
        if($harvest_farms){
            foreach $v (@{$value}){
                $target_id = $v;
                
                $curl->setopt(CURLOPT_POST, 1);
                $url = 'http://'.$server.'.grepolis.com/game/'.$page.'?action='.$action.'&town_id='.$town_id.'&h='.$h;
                $curl->setopt(CURLOPT_URL, $url);
                $json = '{"target_id":"'.$target_id.'","claim_type":"normal","time":300,"town_id":"'.$town_id.'","nlreq_id":917182}';    
                $curl->setopt(CURLOPT_POSTFIELDS, 'json='.$json);
                
                my $response_body = '';
                open(my $fileb, ">", \$response_body);
                $curl->setopt(CURLOPT_WRITEDATA,$fileb);
                
                $retcode = $curl->perform;
                
                my $response_code = $curl->getinfo(CURLINFO_HTTP_CODE);
                print "Farm get harvesr retcode $response_code; TownId $town_id farmId $target_id \n";
                
                #print "=======================================\n";
                #print "Datetime ".join(' ', localtime(time))."\n";
                #print "Harvest from $target_id to $town_id \n";
                
                #if ($retcode == 0) {
                #    my $response_code = $curl->getinfo(CURLINFO_HTTP_CODE);
                #    print "Retcode $response_code \n";
                #    print "Output \n".unescape($response_body)."\n";
                #} else {
                #    print "An error happened: $retcode ".$curl->strerror($retcode)." ".$curl->errbuf."\n";
                #}
                #print "\n=======================================\n";
            }
        }
        
        if($build){
            
            $page = 'building_main';
            $action = 'index';
            
            $curl->setopt(CURLOPT_POST, 0);
            $json = '{"town_id":"'.$town_id.'","nlreq_id":917182}';    
            $url = 'http://'.$server.'.grepolis.com/game/'.$page.'?action='.$action.'&town_id='.$town_id.'&h='.$h.'&json='.$json;
            $curl->setopt(CURLOPT_URL, $url);
            
            my $response_body = '';
            open(my $fileb, ">", \$response_body);
            $curl->setopt(CURLOPT_WRITEDATA,$fileb);
            $retcode = $curl->perform;
            
            if ($retcode == 0) {
                my $response_code = $curl->getinfo(CURLINFO_HTTP_CODE);
                $response_body =~ m/({.*})/;
                my %hash = ( JSON->new->allow_nonref->decode( unescape($1) )->{'html'} =~ /<div\sclass="name\ssmall\sbold"><a\sonclick="Layout.buildingWindow.open\('[\w\s]+'\);"\shref="#">([\w\s]+)<\/a><\/div>[\t\s\n\r]+<a\shref="#"\sonclick="BuildingMain.buildBuilding\('\w+',\s(\d+)\);/g );
                
                my $to_build = '';
                
                if(defined $hash{'Senate'} && $hash{'Senate'}<25){
                    $to_build = 'main';
                }elsif(defined $hash{'Farm'}){
                    $to_build = 'farm';
                }elsif(defined $hash{'Warehouse'}){
                    $to_build = 'storage';
                }elsif(defined $hash{'Academy'}){
                    $to_build = 'academy';
                }elsif(defined $hash{'Barracks'}){
                    $to_build = 'barracks';
                }elsif(defined $hash{'Harbor'}){
                    $to_build = 'docks';
                }
                
                if($to_build ne ''){
                    
                    $action = 'build';
                    
                    $curl->setopt(CURLOPT_POST, 1);
                    $url = 'http://'.$server.'.grepolis.com/game/'.$page.'?action='.$action.'&town_id='.$town_id.'&h='.$h;
                    $curl->setopt(CURLOPT_URL, $url);
                    $json = '{"building":"main","level":5,"wnd_main":{"typeinforefid":0,"type":10},"wnd_index":1,"town_id":"'.$town_id.'","nlreq_id":224625}';    
                    
                    	
                    $curl->setopt(CURLOPT_POSTFIELDS, 'json='.$json);
                    
                    my $response_body = '';
                    open(my $fileb, ">", \$response_body);
                    $curl->setopt(CURLOPT_WRITEDATA,$fileb);
                    
                    $retcode = $curl->perform;
                    
                    my $response_code = $curl->getinfo(CURLINFO_HTTP_CODE);
                    print "Build ".$to_build." retcode $response_code; TownId $town_id\n";
                }
            } else {
                print "An error happened: $retcode ".$curl->strerror($retcode)." ".$curl->errbuf."\n";
            }
        }
    }
    
    if($harvest_chiken){
        
        my @towns = keys %{$_[0]};
        
        $town_id = @towns[int(rand($#towns))];
            
        $curl->setopt(CURLOPT_POST, 0);
        
        $page = 'easter';
        $action = 'index';
        $json = '{"town_id":"'.$town_id.'","nlreq_id":917182}';
        $url = 'http://ru8.grepolis.com/game/'.$page.'?action='.$action.'&town_id='.$town_id.'&h='.$h.'&json='.uri_encode($json);
        $curl->setopt(CURLOPT_URL, $url);
        
        my $response_body = '';
        open(my $fileb, ">", \$response_body);
        $curl->setopt(CURLOPT_WRITEDATA,$fileb);
        $retcode = $curl->perform;
        
        if ($retcode == 0) {
            my $response_code = $curl->getinfo(CURLINFO_HTTP_CODE);
            print "Chicken index retcode $response_code; TownId $town_id \n";
            #print "Output \n".unescape($response_body)."\n";

            $response_body =~ m/({.*})/;
            $json = JSON->new->allow_nonref;
            my $resp = $json->decode( unescape($1) );
            
            if(defined $resp->{'data'}->{'food_search_ends_at'}){
                if( defined$resp->{'data'}->{'food_found'}){
                    my $grass = $resp->{'data'}->{'food_found'}->{'grass'};
                    my $worms = $resp->{'data'}->{'food_found'}->{'grass'};
                    my $corn = $resp->{'data'}->{'food_found'}->{'grass'};
                    
                    $action = 'collect';
                    $json = '{"town_id":"'.$town_id.'","nlreq_id":917182}';
                    $url = 'http://ru8.grepolis.com/game/'.$page.'?action='.$action.'&town_id='.$town_id.'&h='.$h.'&json='.uri_encode($json);
                    $curl->setopt(CURLOPT_URL, $url);
                    my $response_body = '';
                    open(my $fileb, ">", \$response_body);
                    $curl->setopt(CURLOPT_WRITEDATA,$fileb);
                    $retcode = $curl->perform;
                    
                    print "Chicken collect retcode $response_code; TownId $town_id \n";
                    if($grass == 0 && $worms == 0 && $corn == 0){
                        print "Nothing found \n";
                    }
                }
            }
            
            $action = 'start_search';
            $json = '{"duration":300, "town_id":"'.$town_id.'","nlreq_id":917182}';
            $url = 'http://ru8.grepolis.com/game/'.$page.'?action='.$action.'&town_id='.$town_id.'&h='.$h.'&json='.uri_encode($json);
            $curl->setopt(CURLOPT_URL, $url);
            my $response_body = '';
            open(my $fileb, ">", \$response_body);
            $curl->setopt(CURLOPT_WRITEDATA,$fileb);
            $retcode = $curl->perform;
            
            print "Chicken search retcode $response_code; TownId $town_id \n";
            
        } else {
            print "An error happened: $retcode ".$curl->strerror($retcode)." ".$curl->errbuf."\n";
        }
    }
}

Process(%towns);