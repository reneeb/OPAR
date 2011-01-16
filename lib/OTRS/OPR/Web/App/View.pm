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
    
    $notifications{NOTIFICATIONS} = $registered_notifications if $registered_notifications;
    
    $template .= '.tmpl' if $template !~ m{\.tmpl\z}xms;

    $tmpl->param(
        BODY        => $tmpl_path . $template,
        __SKRIPT__ => 'test2',
        %{$self->stash},
        %notifications,
    );
    
    return $tmpl->output;
}

1;
