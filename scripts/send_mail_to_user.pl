#!/usr/bin/perl

use strict;
use warnings;

use File::Basename;
use File::Temp;
use Mail::Sender;
use Path::Class;

my $dir;

BEGIN {
    $dir = dirname __FILE__;
}

use lib "$dir/../lib";

use OTRS::OPR::DB::Schema;
use OTRS::OPR::Web::App::Config;

my $configfile = $ENV{OPAR_CONFIG} || Path::Class::File->new( $dir, 'conf', 'base.yml' )->stringify;
my $config     = OTRS::OPR::Web::App::Config->new(
    $configfile,
);

my $db           = $config->get( 'db.name' );
my $host         = $config->get( 'db.host' );
my $type         = $config->get( 'db.type' );
my $schema_class = $config->get( 'db.schema' );
my $schema       = OTRS::OPR::DB::Schema->connect(
    "DBI:$type:$db:$host",
    $config->get( 'db.user' ),
    $config->get( 'db.pass' ),
    $schema_class,
);

$schema->storage->debug(1);

print "Subject: ";
chomp( my $subject = <STDIN> );

print "Body: ";
my @body = <STDIN>;

my $mailer = Mail::Sender->new({
    smtp      => $config->get( 'mail.smtp.host' ),
    from      => $config->get( 'mail.from' ),
    auth      => 'LOGIN',
    authid    => $config->get( 'mail.smtp.user' ),
    authpwd   => $config->get( 'mail.smtp.pass' ),
});

my @users = $schema->resultset( 'opr_user' )->search();

for my $user ( @users ) {
    my $username = $user->user_name;

    my $text = join '', @body;
    $text =~ s{\$USER\$}{$username}g;

#    print STDERR $text;
#    next;

    $mailer->MailMsg({
        to        => $user->mail,
        subject   => $subject,
        msg       => $text,
    });
}
