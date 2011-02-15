package OTRS::OPR::DB::Schema;

use base qw/DBIx::Class::Schema/;
use DBIx::Class::Log4perl;

__PACKAGE__->logger_conf( '/home/opar/opar_sources/conf/logging.web.conf' );

__PACKAGE__->load_namespaces;

1;