package OTRS::OPR::Web::Guest::Feed;

use strict;
use warnings;

use parent qw(OTRS::OPR::Web::App);

use File::Spec;
use OTRS::OPR::DAO::Author;
use OTRS::OPR::DAO::Package;
use OTRS::OPR::DAO::Comment;
use OTRS::OPR::DB::Helper::Author  qw(id_by_uppercase);
use OTRS::OPR::DB::Helper::Package qw(:all);
use OTRS::OPR::Web::App::Forms     qw(:all);

sub setup {
    my ($self) = @_;

    $self->main_tmpl( $self->config->get('templates.guest') );
    
    my $startmode = 'start';
    my $param     = $self->param( 'run' );
    if( $param ){
        $startmode = $param;
    }

    $self->start_mode( $startmode );
    $self->mode_param( 'rm' );
    $self->run_modes(
        AUTOLOAD        => \&start, # page with decision: create a new feed, edit a feed
        config          => \&edit_config,
        save_config     => \&save_config,
        add_dist        => \&add_dist,
        get             => \&get_feed,
    );
}


1;