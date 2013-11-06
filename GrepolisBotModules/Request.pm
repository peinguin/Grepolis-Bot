package GrepolisBotModules::Request;

use strict;
use warnings;

use Config::IniFiles;
use WWW::Curl::Easy;
use URI::Encode qw(uri_encode uri_decode);
use JSON;
use Data::Dumper;
 
use Exporter qw(import);
our @EXPORT_OK = qw(request base_request);

my $cfg = Config::IniFiles->new( -file => "config.ini" );
my $sid = $cfg->val( 'security', 'sid' );
my $server = $cfg->val( 'security', 'server' );
my $h = $cfg->val( 'security', 'h' );

my @cookies = (
    'cid=1514937687',
    'PHPSESSID=66heoqi60jquur1005c5pm6uu0',
    'sid='.$sid,
    'logged_in=true'
);

my @headers = ('Accept: text/plain, */*; q=0.01');
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

sub request {
    my ($page, $action, $town_id, $json, $post) = @_;
    my $url = 'http://'.$server.'.grepolis.com/game/'.$page.'?action='.$action.'&town_id='.$town_id;
    return base_request($url, $json, $post);
}

sub base_request {
print "http request start\n";
    my ($url, $body, $post) = @_;

    my $curl = WWW::Curl::Easy->new;
    $curl->setopt(CURLOPT_HEADER,0);
    $curl->setopt(CURLOPT_HTTPHEADER, \@headers);

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

    if($url =~ /\?/){
        $url .= '&';
    }else{
        $url .= '?';
    }
    $url .= 'h='.$h;

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
                        $arg->{'type'} ne 'building_finished' &&
                        $arg->{'type'} ne 'newreport'
                    ){
                        if(
                            $arg->{'type'} eq 'backbone' &&
                            $arg->{'subject'} eq 'Town'
                        ){
                            #TODO: update town info
                            print Dumper(JSON->new->allow_nonref->decode($arg->{'param_str'}));
                        }else{
                            print Dumper($arg);
                        }
                    }
                }
            }
        }
print "http request end\n";
        return $response_body;
    }
}
 
1;