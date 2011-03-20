package OTRS::OPR::DB::Helper::Author;

use base 'OTRS::OPR::Exporter::Aliased';

our @EXPORT_OK = qw(
    list
    id_by_uppercase
);

sub list {
    my ($self,%params) = @_;
    
    my $like = '';
    my ($short,$initial);
    
    if ( $params{short} && $params{short} =~ m{\A [a-zA-Z]{2} \z }x ) {
        $like  = $params{short};
        $short = 1;
    }
    elsif ( $params{initial} && $params{initial} =~ m{\A [a-zA-Z] \z }x ) {
        $like    = $params{initial};
        $initial = 1;
    }
    
    my @list = $self->table( 'opr_user' )->search({
        user_name => { LIKE => "$like\%" },
    });
    
    if ( $params{active} ) {
        @list = grep{ $_->active }@list;
    }
    
    my %authors;
    
    if ( $short ) {
        %authors = map{ uc( $_->user_name ) => 1 }@list;
    }
    elsif ( $initial ) {
        %authors = map{ (uc substr $_->user_name, 0, 2) => 1 }@list
    }
    else {
        %authors = map{ (uc substr $_->user_name, 0, 1) => 1 }@list;
    }
    
    return sort keys %authors;
}

sub id_by_uppercase {
    my ($self,$up) = @_;
    
    my @list = $self->table( 'opr_user' )->search({
        user_name => { LIKE => "$up" },
    });
    
    return if !@list;
    return $list[0]->user_id;
}

1;