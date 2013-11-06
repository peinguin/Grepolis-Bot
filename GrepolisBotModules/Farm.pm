package GrepolisBotModules::Farm;

use GrepolisBotModules::Request;

use AnyEvent;
use JSON;
use Data::Dumper;

my $get_farm_data = sub {
	
	my $self = shift;

    my $resp = JSON->new->allow_nonref->decode(
        GrepolisBotModules::Request::request(
                'farm_town_info',
                'claim_info',
                $self->{'town'}->getId,
                '{"id":"2097"}',
                0
            )
        );

    $self->{'name'} = $resp->{'json'}->{'json'}->{'farm_town_name'};

    $resp->{'json'}->{'html'} =~ /<h4>You\sreceive:\s\d+\sresources<\/h4><ul><li>(\d+)\swood<\/li><li>\d+\srock<\/li><li>\d+\ssilver\scoins<\/li><\/ul>/;

    $self->{'resources_by_request'} = $1;
};

my $tick;
$tick = sub {

	my $self = shift;

    $json = '{"target_id":"'.$self->{'id'}.'","claim_type":"normal","time":300,"town_id":"'.$self->{'town'}->getId.'","nlreq_id":917182}';
    my $response_body = GrepolisBotModules::Request::request('farm_town_info', 'claim_load', $self->{'town'}->getId, $json, 1);

    GrepolisBotModules::Async::delay( 360 + int(rand(240)), sub { $self->$tick} );
};

sub new {
    my $class = shift;

    my $self = {
        id => shift,
        name => undef,
        resources_by_request => undef,
        town => shift
     };

    bless $self, $class;
    
    $self->$get_farm_data;
    $self->$tick;

    return $self;
}

1;