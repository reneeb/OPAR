package OTRS::OPR::DB::Helper::Job;

use base 'OTRS::OPR::Exporter::Aliased';

our @EXPORT_OK = qw(
    create_job
    find_job
);

sub create_job {
    my ($self,$params) = @_;
    
    return if !($params{id} and $params{type});
    
    my ($type) = $self->table( 'opr_job_type' )->search({
        type_label => $params{type},
    })->all;
    
    return if !$type;
    
    my ($existing_job) = $self->table( 'opr_job_queue' )->search({
        type_id    => $type->type_id,
        package_id => $params{id},
    });
    
    return if $existing_job;
    
    my $job = $self->table( 'opr_job_queue' )->create({
        type_id    => $type->type_id,
        package_id => $params{id},
        created    => time,
    });
    
    return $job->job_id;
}

sub find_job {
    my ($self,$params) = @_;
    
    return if !($params{id} and $params{type});
    
    my ($type) = $self->table( 'opr_job_type' )->search({
        type_label => $params{type},
    })->all;
    
    return if !$type;
    
    my ($existing_job) = $self->table( 'opr_job_queue' )->search({
        type_id    => $type->type_id,
        package_id => $params{id},
    });
    
    return $existing_job;
}

1;