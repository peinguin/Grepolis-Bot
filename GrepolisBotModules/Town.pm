package GrepolisBotModules::Town;

use strict;
use warnings;

use GrepolisBotModules::Request;
use GrepolisBotModules::Farm;
use GrepolisBotModules::Log;

use JSON;

my $get_town_data = sub {
    my( $self ) = @_;

    my $resp = JSON->new->allow_nonref->decode(
        GrepolisBotModules::Request::request(
                'town_info',
                'go_to_town',
                $self->{'id'},
                undef,
                0
            )
        );

    $self->{'max_storage'} = $resp->{'json'}->{'max_storage'};

    my $json =  {types => [{type => 'backbone'},{type => "map", param => {x => 0,y => 0}}]};
    $resp = JSON->new->allow_nonref->decode(
        GrepolisBotModules::Request::request(
                'data',
                'get',
                $self->{'id'},
                $json,
                1
            )
        );

    foreach my $arg (@{$resp->{'json'}->{'backbone'}->{'collections'}}) {
        if(
            defined $arg->{'model_class_name'} &&
            $arg->{'model_class_name'} eq 'Town'
        ){
            my $town = pop($arg->{'data'});
            $self->setResources($town->{'last_iron'}, $town->{'last_stone'}, $town->{'last_wood'});
        }
    }

    foreach my $data (@{$resp->{'json'}->{'map'}->{'data'}->{'data'}->{'data'}} ) {
        foreach my $key (keys %{$data->{'towns'}}) {
            if(
                defined $data->{'towns'}->{$key}->{'relation_status'} &&
                $data->{'towns'}->{$key}->{'relation_status'} == 1
            ){
                my $village = new GrepolisBotModules::Farm($data->{'towns'}->{$key}->{'id'}, $self);
                push($self->{'villages'}, $village);
            }
        }
    }
};

my $build_something;

$build_something = sub {
    my $self = shift;

    GrepolisBotModules::Log::echo 0, "Build request ".$self->{'id'}."\n";
    my $response_body = GrepolisBotModules::Request::request('building_main', 'index', $self->{'id'}, {town_id => $self->{'id'}}, 0);

    $response_body =~ m/({.*})/;

    my %hash = ( JSON->new->allow_nonref->decode( $1 )->{'json'}->{'html'} =~ /BuildingMain.buildBuilding\('([^']+)',\s(\d+)\)/g );
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
        my $response_body = GrepolisBotModules::Request::request(
            'building_main',
            'build',
            $self->{'id'},
            {building => $to_build, level => 5, wnd_main => {typeinforefid => 0, type => 9}, wnd_index => 0, town_id => $self->{'id'}},
            1
        );
    }

    my $time_wait = undef;

    my $json = JSON->new->allow_nonref->decode($response_body);
    if(defined $json->{'notifications'}){
        foreach my $arg (@{$json->{'notifications'}}) {
            if(
                $arg->{'type'} eq 'backbone' &&
                $arg->{'subject'} eq 'BuildingOrder'
            ){
                my $order = JSON->new->allow_nonref->decode($arg->{'param_str'})->{'BuildingOrder'};
                $time_wait = $order->{'to_be_completed_at'} - $order->{'created_at'};
            }
        }
    }

    if(defined $time_wait){
        GrepolisBotModules::Log::echo 0, "Town ".$self->{'id'}." build ".$to_build."\n";
        GrepolisBotModules::Async::delay( $time_wait + int(rand(60)), sub {$self->$build_something} );
    }else{
        GrepolisBotModules::Log::echo 0, "Town ".$self->{'id'}." can not build. Waiting\n";
        GrepolisBotModules::Async::delay( 600 + int(rand(300)), sub {$self->$build_something} );
    }
};

sub setResources{
    my $self = shift;
    my $iron = shift;
    my $stone = shift;
    my $wood = shift;

    $self->{'iron'} = $iron;
    $self->{'wood'} = $wood;
    $self->{'stone'} = $stone;

    GrepolisBotModules::Log::echo 1, "Town ".$self->{'id'}." resources updates iron-".$self->{'iron'}.", stone-".$self->{'stone'}.", wood-".$self->{'wood'}."\n";
}

sub needResources{
    my $self = shift;
    my $resources_by_request = shift;

    if(
        $self->{'iron'} + $resources_by_request < $self->{'max_storage'} ||
        $self->{'wood'} + $resources_by_request < $self->{'max_storage'} ||
        $self->{'stone'} + $resources_by_request < $self->{'max_storage'}
    ){
        return 1;
    }
    return 0;
}

sub toUpgradeResources{
    my $self = shift;

    return {
        wood => int($self->{'iron'}/5),
        stone => int($self->{'wood'}/5),
        iron => int($self->{'stone'}/5),
    };
}

sub getId{
    my $self = shift;
    return $self->{'id'};
}

sub new {
    my $class = shift;
    my $self = {
        id => shift,
        villages => [],
        max_storage => undef,
        iron => undef,
        wood => undef,
        stone => undef
     };

    bless $self, $class;
    
    GrepolisBotModules::Log::echo 0, "Town ".$self->{'id'}." init started\n";

    $self->$get_town_data;
    GrepolisBotModules::Log::echo 0, "Town ".$self->{'id'}." data gettings finished\n";
    $self->$build_something;
    GrepolisBotModules::Log::echo 0, "Town ".$self->{'id'}." build started\n";

    return $self;
}

1;