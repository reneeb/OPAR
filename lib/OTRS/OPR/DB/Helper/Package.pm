package OTRS::OPR::DB::Helper::Package;

use strict;
use warnings;

use parent 'OTRS::OPR::Exporter::Aliased';

use OTRS::OPR::Web::Utils qw(time_to_date);

our @EXPORT_OK = qw(
    page
);

sub page {
    my ($self,$page,$params) = @_;
    
    my $rows = $self->config->get( 'rows.search' );
    
    my %search_clauses;
    if ( exists $params->{search} ) {
        my $term = $params->{search};
        $term    =~ tr/*/%/;
        for my $field ( 'opr_package_names.package_name', 'description' ) {
            $search_clauses{$field} = { LIKE => '%' . $term . '%' };
        }
    }
    
    if ( exists $params->{uploader} ) {
        $search_clauses{uploaded_by} = $params->{uploader};
    }
    
    my $resultset = $self->table( 'opr_package' )->search(
        {
            is_in_index => 1,
            %search_clauses,
        },
        {
            page     => $page,
            rows     => $rows,
            order_by => 'package_id',
            group_by => [ 'package_name' ],
            join     => 'opr_package_names',
        },
    );
    
    my @packages = $resultset->all;    
    my $pages    = $resultset->pager->last_page || 1;
    
    my @packages_for_template;
    for my $package ( @packages ) {
        
        # show just a short excerpt of the text if it is too long
        my $text = $package->package_name;
        $text    = substr( $text, 0, 37 ) . '...' if $params->{short} and 40 < length $text;
        
        # show just a short excerpt of the description if it is too long
        my $desc = $package->description;
        $desc    = substr( $desc, 0, 57 ) . '...' if $params->{short} and 60 < length $desc;
        
        my ($author) = $package->opr_package_author;
        
        # create the infos for the template
        push @packages_for_template, {
            NAME        => $text,
            VERSION     => $package->version,
            DESCRIPTION => $desc,
            AUTHOR      => ($author ? $author->user_name : '' ),
            DATE        => time_to_date( $self, $package->upload_time ),
        };
    }
    
    return ( \@packages_for_template, $pages );
}

1;