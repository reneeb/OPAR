package OTRS::OPR::DB::Helper::User;

use base 'OTRS::OPR::Exporter::Aliased';

our @EXPORT_OK = qw(
    check_credentials
    list
);

sub check_credentials {
    my ($self,$params) = @_;
    
    my $logger = $self->logger;
    
    return if !($params->{user} and $params->{password});
    
    my $username = $params->{user};
    my $password = crypt $params->{password}, $self->config->get( 'password.salt' );
    
    my $check    = $params->{password};
    $logger->debug( "Try $username -> $check -> $password" );
    
    my ($user) = $self->table( 'opr_user' )->search({
        user_name     => $username,
        user_password => $password,
    })->all;
    
    if ( !$user ) {
        $logger->info( "Login for $username not successful" );
        return;
    }
    
    $logger->debug( "Login $username successful" );
    
    my $session = $self->session;
    $session->session->force_new;
    
    my $session_id = $session->id;
    $user->session_id( $session_id );
    $user->update;
    
    $logger->trace( "Session ID for $user: $session_id" );
    
    return 1;
}

sub list {
}

1;