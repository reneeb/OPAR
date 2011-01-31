package OTRS::OPR::App::AttributeInformation;

use Moose;
extends 'Moose::Meta::Attribute';

has is_trackable => (
    is  => 'rw',
    isa => 'Int',
);

no Moose;

1;