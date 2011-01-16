package OTRS::OPR::DB::Helper::User;

use base 'OTRS::OPR::Exporter::Aliased';

our @EXPORT_OK = qw(
    check_credentials
    list
);

sub check_credentials {
    my ($self,$params) = @_;
    
    my $logger = $self->logger;
    
    return if !($params{user} and $params{password});
    
    my $password = crypt $params{password}, $self->config->get( 'password.salt' );
    
    my ($user) = $self->table( 'opr_user' )->search({
        user_name     => $params{user},
        user_password => $password,
    })->all;
    
    if ( !$user ) {
        $logger->info( "Login for $params{user} not successful" );
        return;
    }
    
    $logger->debug( "Login $params{user} successful" );
    
    my $session = $self->session;
    $session->session->force_new;
    
    my $session_id = $session->session_id;
    $user->session_id( $session_id );
    $user->update;
    
    $logger->trace( "Session ID for $params{user}: $session_id" );
    
    return 1;
}

sub list {
}

1;