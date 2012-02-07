#!/usr/bin/perl

use strict;
use warnings;
use WWW::Curl::Easy;
use URI::Escape;
use Config::IniFiles;


my %ini;
tie %ini, 'Config::IniFiles', ( -file => "config.ini" );

my $sid = $ini{security}{sid};#$cfg->val( 'security', 'sid' );
my $h = $ini{security}{h};#$cfg->val( 'security', 'h' );
my @numbers = (1, 2, 3, 4, 5);

my %towns = ();

foreach my $town ($ini{towns}){
    my($key, $value) = %$town;
    $towns{$key} = [ split(', ',$value) ];
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

#print join("\n", @headers);die;

sub getHarvest(\%){
    my $curl = WWW::Curl::Easy->new;
    
    my $page = 'farm_town_info';
    my $action = 'claim_load';
    my $town_id = '';
    my $url = '';
    my $json = '';
    my $target_id = '';
    my $retcode = 0;

    $curl->setopt(CURLOPT_HEADER,0);
    $curl->setopt(CURLOPT_HTTPHEADER, \@headers);
    $curl->setopt(CURLOPT_POST, 1);
    
    my $response_body;
    open(my $fileb, ">", \$response_body);
    $curl->setopt(CURLOPT_WRITEDATA,$fileb);

    
    my($key, $value);
    while ( ($key, $value) = each(%{$_[0]}) ) {
        $town_id = $key;
        my ($k, $v);
        foreach $v (@{$value}){
            $target_id = $v;
            
            $url = 'http://ru8.grepolis.com/game/'.$page.'?action='.$action.'&town_id='.$town_id.'&h='.$h;
            $curl->setopt(CURLOPT_URL, $url);
            $json = '{"target_id":"'.$target_id.'","claim_type":"normal","time":300,"town_id":"'.$town_id.'","nlreq_id":917182}';    
            $curl->setopt(CURLOPT_POSTFIELDS, 'json='.$json);
            
            $retcode = $curl->perform;
            
            print "=======================================\n";
            print "Datetime ".join(' ', localtime(time))."\n";
            print "Harvest from $target_id to $town_id \n";
            
            if ($retcode == 0) {
                my $response_code = $curl->getinfo(CURLINFO_HTTP_CODE);
                print "Retcode $response_code \n";
                print "Output \n".$response_body."\n";
            } else {
                print "An error happened: $retcode ".$curl->strerror($retcode)." ".$curl->errbuf."\n";
            }
            print "\n=======================================\n";
        }
    }
}

getHarvest(%towns);