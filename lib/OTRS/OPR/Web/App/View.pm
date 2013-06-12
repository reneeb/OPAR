package OTRS::OPR::Web::App::View;

use strict;
use warnings;

use HTML::Template::Compiled;
use OTRS::OPR::Web::App::Config;

use Data::Dumper;

use base qw(Exporter);
our @EXPORT_OK = qw(view);

our $VERSION = 0.01;


sub view{
    my ($self) = @_;
    
    my $template  = $self->template;
    my $main_tmpl = $self->main_tmpl;
    my $config    = $self->config;

    my $test      = defined $main_tmpl ? $main_tmpl : $config->get('templates.base');
	
    my $tmpl_path = $config->get( 'paths.base' ) . $config->get( 'paths.templates' );
    my $basetmpl  = $tmpl_path . $test;
    
    my $tmpl = HTML::Template::Compiled->new( 
        filename       => $basetmpl, 
        default_escape => 'html',
        use_query      => 1,
    );
    
    my %notifications;
    my $registered_notifications = $self->notify;
    
    $notifications{NOTIFICATIONS} = $registered_notifications || [];
    
    for my $notification ( @{ $notifications{NOTIFICATIONS} } ) {
        $notification->{include} = $tmpl_path . $notification->{include} . '.tmpl';
    }
    
    $template .= '.tmpl' if $template !~ m{\.tmpl\z}xms;
    
    my $username = '';
    $username = $self->user->user_name if $self->user;

    my @frameworks = map{ VERSION => $_->framework }$self->table( 'opr_framework_versions' )->search(
        {},
        { order_by => 'framework', }
    );


    $tmpl->param(
        BODY         => $tmpl_path . $template,
        __SCRIPT__   => $self->base_url,
        __INDEX__    => $self->script_url( 'index' ),
        __AUTHOR__   => $self->script_url( 'author' ),
        __ADMIN__    => $self->script_url( 'admin' ),
        __LOGGEDIN__ => $username,
        frameworks   => \@frameworks,
        %{$self->stash},
        %notifications,
    );
    
    return $tmpl->output;
}

1;
