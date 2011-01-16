package OTRS::OPR::DAO::User;

use Moose;

extends 'OTRS::OPR::DAO::Base';

has session_id => ( is => 'rw' );

no Moose;

1;