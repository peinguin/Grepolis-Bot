package GrepolisBotModules::Request;

use strict;
use warnings;

use GrepolisBotModules::Log;
use WWW::Curl::Easy;
use URI::Encode qw(uri_encode uri_decode);
use JSON;
 
my @cookies = undef;
my @headers = undef;
my $config  = undef;
my $h = undef;

my $nlreq_id = undef;

sub request {
    my ($page, $action, $town_id, $json, $post) = @_;
    my $url = 'http://'.$config->{'server'}.'.grepolis.com/game/'.$page.'?action='.$action.'&town_id='.$town_id;
    return base_request($url, $json, $post);
}

sub base_request {

    GrepolisBotModules::Log::echo 0, "http request start\n";

    my ($url, $body, $post) = @_;

    my $curl = WWW::Curl::Easy->new;
    $curl->setopt(CURLOPT_HEADER,0);
    $curl->setopt(CURLOPT_HTTPHEADER, \@headers);

    if(defined $nlreq_id > 0){
        $body->{'nlreq_id'} = $nlreq_id;
    }

    $body = JSON->new->allow_nonref->encode($body);

    if(defined $post && $post){
        $curl->setopt(CURLOPT_POST, 1);
        $curl->setopt(CURLOPT_POSTFIELDS, 'json='.$body);
    }else{
        if(defined $body){
            if($url =~ /\?/){
                $url .= '&';
            }else{
                $url .= '?';
            }
            $url .= 'json='.uri_encode($body);
        }
    }
    if(defined $h){
        if($url =~ /\?/){
            $url .= '&';
        }else{
            $url .= '?';
        }
        $url .= 'h='.$h;
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

        if($response_body =~ /^{/){
            my $json = JSON->new->allow_nonref->decode( $response_body )->{'json'};
            if(defined $json->{'notifications'}){
                foreach my $arg (@{$json->{'notifications'}}) {
                    if(
                        (
                            $arg->{'type'} ne 'newaward' &&
                            $arg->{'type'} ne 'building_finished' &&
                            $arg->{'type'} ne 'newreport' &&
                            (
                                $arg->{'type'} ne 'backbone' ||
                                $arg->{'type'} eq 'backbone' && 
                                (
                                    !(defined $arg->{'subject'}) ||
                                    (
                                        $arg->{'subject'} ne 'BuildingOrder' &&
                                        $arg->{'subject'} ne 'Town' &&
                                        $arg->{'subject'} ne 'PlayerRanking' &&
                                        $arg->{'subject'} ne 'Buildings' &&
                                        $arg->{'subject'} ne 'IslandQuest' &&
                                        $arg->{'subject'} ne 'TutorialQuest' &&
                                        $arg->{'subject'} ne 'Units' &&
                                        $arg->{'subject'} ne 'UnitOrder' &&
                                        $arg->{'subject'} ne 'CastedPowers' &&
                                        $arg->{'subject'} ne 'UnitOrder' &&
                                        $arg->{'subject'} ne 'CommandsMenuBubble' &&
                                        $arg->{'subject'} ne 'Trade'
                                    )
                                )
                            ) &&
                            (
                                $arg->{'type'} ne 'systemmessage' ||
                                $arg->{'type'} eq 'systemmessage' && 
                                (
                                    !(defined $arg->{'subject'}) ||
                                    (
                                        $arg->{'subject'} ne 'menububbleTrade' &&
                                        $arg->{'subject'} ne 'menububbleMovement' &&
                                        $arg->{'subject'} ne 'doRefetchBar' &&
                                        $arg->{'subject'} ne 'menububbleTroops'
                                    )
                                )
                            )
                        ) &&
                        $arg->{'type'} ne 'incoming_support' &&
                        $arg->{'type'} ne 'phoenician_salesman_arrived' &&
                        $arg->{'type'} ne 'resourcetransport'
                    ){
                        if($arg->{'type'} eq 'botcheck'){
                            die('Do bot cheching!');
                        }else{
                            GrepolisBotModules::Log::dump 5, $arg;
                        }
                    }

                    if(defined $arg->{'id'}){
                        $nlreq_id = int($arg->{'id'});
                    }
                }
            }
        }
        GrepolisBotModules::Log::echo 0, "http request end\n";
        return $response_body;
    }
}

sub setH{
    $h = shift;
}

sub init{

    $config = shift;

    @cookies = (
        'cid=1514937687',
        'PHPSESSID=66heoqi60jquur1005c5pm6uu0',
        'sid='.$config->{'sid'},
        'logged_in=true'
    );

    @headers = ('Accept: text/plain, */*; q=0.01');
    push(@headers, 'Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7');
    push(@headers, 'Accept-Encoding:');
    push(@headers, 'Accept-Language: en-us,en;q=0.5');
    push(@headers, 'Cache-Control: no-cache');
    push(@headers, 'Connection: keep-alive');
    push(@headers, 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8');
    push(@headers, 'Cookie: '.join('; ', @cookies));
    push(@headers, 'Host: ru8.grepolis.com');
    push(@headers, 'Pragma: no-cache');
    push(@headers, 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:9.0.1) Gecko/20100101 Firefox/9.0.1 Iceweasel/9.0.1');
    push(@headers, 'X-Requested-With: XMLHttpRequest');
}
 
1;
