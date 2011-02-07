package OTRS::OPR::Web::App::Mailer;

use strict;
use warnings;
use Path::Class;
use Mail::Sender;
use HTML::Template::Compiled;

use OTRS::OPR::Web::App::Config;

sub new{
    my ($class,$config) = @_;
    my $self = bless {}, $class;
    
    $self->_config( $config );

    return $self;
}

sub prepare_mail{
    my ($self,$template,%fields) = @_;

    my $config = $self->_config;
    my $path   = Path::Class::File->new(
        $config->get( 'paths.base' ),
        $config->get( 'paths.templates' ),
        $config->get( 'paths.mails' ),
        $template
    );
    
    my $tmpl = HTML::Template::Compiled->new( filename => $path->stringify );
    $tmpl->param( %fields );

    $self->{_tmpl} = $tmpl;
}

sub send_mail{
    my ($self,%args) = @_;
    
    my $config = $self->_config;

    my $mailer = Mail::Sender->new({
        smtp      => $config->get( 'mail.smtp' ),
        from      => $args{from}    || $config->get( 'mail.from' ),
        auth      => 'LOGIN',
        authid    => $config->get( 'mail.user' ),
        authpwd   => $config->get( 'mail.pass' ),
        on_errors => undef,
    });

    $mailer->MailMsg({
        to        => $args{to}      || $config->get( 'mail.to' ),
        subject   => $args{subject} || $config->get( 'mail.subject' ),
        msg       => $self->{_tmpl}->output,
    });
}

sub _config{
    my ($self,$value) = @_;
    
    $self->{_config} = $value if @_ == 2;

    return $self->{_config};
}

1;
