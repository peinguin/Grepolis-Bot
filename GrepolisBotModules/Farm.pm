package GrepolisBotModules::Farm;

use GrepolisBotModules::Request;
use GrepolisBotModules::Log;

use JSON;

my $get_farm_data = sub {
	
	my $self = shift;

    my $resp = JSON->new->allow_nonref->decode(
        GrepolisBotModules::Request::request(
                'farm_town_info',
                'claim_info',
                $self->{'town'}->getId,
                '{"id":"'.$self->{'id'}.'"}',
                0
            )
        );

    $self->{'name'} = $resp->{'json'}->{'json'}->{'farm_town_name'};
    $resp->{'json'}->{'html'} =~ /<h4>You\sreceive:\s\d+\sresources<\/h4><ul><li>(\d+)\swood<\/li><li>\d+\srock<\/li><li>\d+\ssilver\scoins<\/li><\/ul>/;
    $self->{'resources_by_request'} = $1;
    if($resp->{'json'}->{'html'} =~ /<h4>Upgrade\slevel\s\((\d)\/6\)<\/h4>/ ){
        $self->{'level'} = $1;
    }else{
        die('Level not found');
    }
};

my $upgrade = sub{
	my $self = shift;

	my $donate = $self->{'town'}->toUpgradeResources();

    $json = '{"target_id":'.$self->{'id'}.',"wood":'.$donate->{'wood'}.',"stone":'.$donate->{'stone'}.',"iron":'.$donate->{'iron'}.',"town_id":"'.$self->{'town'}->getId().'"}';
    my $response_body = GrepolisBotModules::Request::request('farm_town_info', 'send_resources', $self->{'town'}->getId(), $json, 1);
    GrepolisBotModules::Log::echo 1, "Village send request. Town ID ".$self->{'town'}->getId()." Village ID ".$self->{'id'}."\n";

    $self->$get_farm_data;
};
my $claim = sub{
	my $self = shift;
	$json = '{"target_id":"'.$self->{'id'}.'","claim_type":"normal","time":300,"town_id":"'.$self->{'town'}->getId.'"}';
    my $response_body = GrepolisBotModules::Request::request('farm_town_info', 'claim_load', $self->{'town'}->getId, $json, 1);

    my $json = JSON->new->allow_nonref->decode($response_body)->{'json'};
    if(defined $json->{'notifications'}){
        foreach my $arg (@{$json->{'notifications'}}) {
            if(
                $arg->{'type'} eq 'backbone' &&
                $arg->{'subject'} eq 'Town'
            ){
                my $town = JSON->new->allow_nonref->decode($arg->{'param_str'})->{'Town'};
                $self->{'town'}->setResources($town->{'last_iron'}, $town->{'last_stone'}, $town->{'last_wood'});
            }
        }
    }

    GrepolisBotModules::Log::echo 1, "Farm ".$self->{'id'}." claim finished\n";
};

my $needUpgrade = sub {
	my $self = shift;
	if($self->{'level'} < 6){
		return true;
	}else{
		return false;
	}
};

my $tick;
$tick = sub {

	my $self = shift;

	if($self->{'town'}->needResources($self->{'resources_by_request'})){
		$self->$claim();
	    GrepolisBotModules::Async::delay( 360 + int(rand(240)), sub { $self->$tick} );
	}elsif($self->$needUpgrade()){
		$self->$upgrade();
		GrepolisBotModules::Async::delay( 600 + int(rand(240)), sub { $self->$tick} );
    }
};

sub new {
    my $class = shift;

    my $self = {
        id => shift,
        name => undef,
        resources_by_request => undef,
        town => shift,
        level => undef
    };
    GrepolisBotModules::Log::echo 0, "Farm ".$self->{'id'}." init started\n";
    bless $self, $class;
    
    $self->$get_farm_data;
    GrepolisBotModules::Log::echo 0, "Farm ".$self->{'id'}." data gettings finished\n";
    $self->$tick;
    GrepolisBotModules::Log::echo 0, "Farm ".$self->{'id'}." ticker started\n";

    return $self;
}

1;