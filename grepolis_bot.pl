<<<<<<< HEAD
=======
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

sub perform_request{
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
    
    my ($page, $action, $town_id, $json, $post) = @_;
    
    my $url = 'http://'.$server.'.grepolis.com/game/'.$page.'?action='.$action.'&town_id='.$town_id.'&h='.$h;
    
    if($post){
        $curl->setopt(CURLOPT_POST, 1);
        $curl->setopt(CURLOPT_POSTFIELDS, 'json='.$json);
    }else{
        $url .= '&json='.uri_encode($json);
    }
    
    $curl->setopt(CURLOPT_URL, $url);
    
    my $response_body = '';
    open(my $fileb, ">", \$response_body);
    $curl->setopt(CURLOPT_WRITEDATA,$fileb);
    
    my $retcode = $curl->perform;
    
    if ($retcode != 0) {
        print "An error happened: $retcode ".$curl->strerror($retcode)." ".$curl->errbuf."\n";
        die;
    }else{
        return $response_body;
    }
}

my $harvest_chiken = $cfg->val( 'options', 'harvest_chiken' );
my $build = $cfg->val( 'options', 'build' );
my $harvest_farms = $cfg->val( 'options', 'harvest_farms' );
my $donate_for_villages = $cfg->val( 'options', 'donate_for_villages' );
my $donate = $cfg->val( 'options', 'donate' );

sub Process(\%){
    
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
            my $response_body = perform_request($page, $action, $town_id, $json, 0);
            
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
            }elsif(defined $hash{'Silver mine'}){
                $to_build = 'ironer';
            }
            
            if($to_build ne ''){
                $action = 'build';
                $json = '{"building":"'.$to_build.'","level":5,"wnd_main":{"typeinforefid":0,"type":10},"wnd_index":1,"town_id":"'.$town_id.'","nlreq_id":224625}';
                my $response_body = perform_request($page, $action, $town_id, $json, 1);
                
                print $response_body."\n";
                
                print "Build ".$to_build." ; TownId $town_id\n";
            }
        }
        
        my ($wood_donate, $stone_donate, $iron_donate) = (0, 0, 0);
        
        if($donate_for_villages){
            $page = 'data';
            $action = 'get';
            $json = '{"types":[{"type":"map","param":{"x":0,"y":0}},{"type":"bar"}]}';
            my $response_body = perform_request($page, $action, $town_id, $json, 0);
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
                my $response_body = perform_request($page, $action, $town_id, $json, 0);
                my ($now, $next) = ($response_body =~ /<div\sclass=\\\"farm_build_bar_amount\\\">(\d+)\\\/(\d+)<\\\/div>/g);
            
                if($now < 150000){
                    $action = 'send_resources';
                    $json = '{"target_id":'.$target_id.',"wood":'.$wood_donate.',"stone":'.$stone_donate.',"iron":'.$iron_donate.',"town_id":"'.$town_id.'","nlreq_id":251650}';
                    my $response_body = perform_request($page, $action, $town_id, $json, 1);
                }
            }
            
            if($harvest_farms){
                my $action = 'claim_load';
                $json = '{"target_id":"'.$target_id.'","claim_type":"normal","time":300,"town_id":"'.$town_id.'","nlreq_id":917182}';
                my $response_body = perform_request($page, $action, $town_id, $json, 1);
                print "Farm get harvest. TownId $town_id farmId $target_id \n";
                
                #print "=======================================\n";
                #print "Datetime ".join(' ', localtime(time))."\n";
                #print "Harvest from $target_id to $town_id \n";
                #    print "Output \n".unescape($response_body)."\n";
                #print "\n=======================================\n";
            }
        }
    }
    
    if($harvest_chiken){
        
        my @towns = keys %{$_[0]};
        
        $town_id = @towns[int(rand($#towns))];
        
        $page = 'easter';
        $action = 'index';
        $json = '{"town_id":"'.$town_id.'","nlreq_id":917182}';
        
        my $response_body = perform_request($page, $action, $town_id, $json, 0);
        
        print "Chicken. TownId $town_id \n";

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
                my $response_body = perform_request($page, $action, $town_id, $json, 0);
                
                print "Chicken collect; TownId $town_id \n";
                if($grass == 0 && $worms == 0 && $corn == 0){
                    print "Nothing found \n";
                }
            }
        }
        
        $action = 'start_search';
        $json = '{"duration":300, "town_id":"'.$town_id.'","nlreq_id":917182}';
        $response_body = perform_request($page, $action, $town_id, $json, 0);
        
        print "Chicken search; TownId $town_id \n";
    }
}

Process(%towns);
>>>>>>> 470c5364b899e46f7d3392c5ea1f724c213ca17e
