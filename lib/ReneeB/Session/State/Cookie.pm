package ReneeB::Session::State::Cookie;

use strict;
use warnings;
use CGI::Cookie;

my $cookiename = 'MyCookie';
my $expiretime = 60;

sub new{
    my ($class) = @_;
    my $self    = bless {}, $class;
    
    return $self;
}

sub cookiename {
    my ($self,$name) = @_;
    
    if ( defined $name ) {
        $self->{__cookiename} = $name;
    }
    
    return $self->{__cookiename} || $cookiename;
}

sub expire {
    my ($self,$seconds) = @_;
    
    if ( $seconds and $seconds =~ m{ \A [0-9]+ \z }xms ) {
        my $minutes = int( $seconds / 60 );
        $self->{__expire} = $minutes;
    }
    
    my $expire = $self->{__expire} || $expiretime;
    return '+' . $expire . 'm';
}

sub update {
    my ($self, $id) = @_;
    $self->save( $id );
}

sub save{
    my ($self, $id) = @_;
    
    my $cookie = CGI::Cookie->new(
        -name    => $self->cookiename,
        -value   => $id,
        -expires => $self->expire,
    );
    print "Set-Cookie: $cookie\n";
}

sub id{
    my ($self) = @_;
    
    my ($id);
    
    my %cookies = CGI::Cookie->fetch;
    my $cookie  = $cookies{ $self->cookiename };
       $id      = $cookie->value if defined $cookie;
    
    return $id;
}

sub delete{
    my ($self) = @_;
    
    my $cookie = CGI::Cookie->new(
        -name    => $self->cookiename,
        -value   => '',
        -expires => 0
    );
    print "Set-Cookie: $cookie\n";
}

1;