package OTRS::OPR::DB::Helper::Passwd;

use base 'OTRS::OPR::Exporter::Aliased';

our @EXPORT_OK = qw(
    temp_passwd
    check_temp_passwd
    delete_temp_passwd
);

sub temp_passwd {
    my ($self,$params) = @_;
    
    return if !( $params->{token} and $params->{user_id} and $params->{created} );
    
    $self->table( 'opr_temp_passwd' )->search({
        user_id => $params->{user_id}
    })->delete;
    
    my $passwd = $self->table( 'opr_temp_passwd' )->create($params);
    
    $passwd->update;
    
    return $passwd->id;
}

sub check_temp_passwd {
    my ($self,$params) = @_;
    
    $self->app->log->debug( 'check_temp_passwd with token: ' . $params->{token} );
    
    return if !$params->{token};
    
    my ($type) = $self->table( 'opr_temp_passwd' )->search({
        token => $params->{token},
    })->all;
    
    $self->app->log->debug( "Found $type" );
    
    return if !$type;
    
    my $expire = $self->opar_config->get( 'formid.passwd_expire' ) || 1200;
    
    $self->app->log->debug( sprintf "User: %s Expire: %s Time: %s", $type->user_id, ($type->created + $expire), time );
    
    return if time > $type->created + $expire;
    return $type->user_id;
}

sub delete_temp_passwd {
    my ($self,$params) = @_;
    
    return if !$params->{token};
    
    my ($type) = $self->table( 'opr_temp_passwd' )->search({
        token => $params->{token},
    })->delete;
}

1;
