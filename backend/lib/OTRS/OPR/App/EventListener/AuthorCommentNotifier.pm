package OTRS::OPR::App::EventListener::AuthorCommentNotifier;

use strict;
use warnings;

use List::Util qw(first);

use MojoX::GlobalEvents;

use OTRS::OPR::DAO::User;
use OTRS::OPR::Web::App::Mailer;

on 'comment_created' => sub {
    my $comment_id = shift;
    my $schema     = shift;
    my $config     = shift;

    return if !( $comment_id && $schema && $config );

    my $comment = $schema->resultset('opr_comments')->search({
        comment_id => $comment_id,
    })->first;

    return if !$comment;

    my $name = $schema->resultset('opr_package_names')->search({
        package_name => $comment->packagename,
    })->first;

    return if !$name;

    my @users    = $name->opr_package_author;
    my ($author) = first{ $_->is_main_author }@users;

    return if !$author;

    my ($user) = $author->opr_user;

    return if !$user;

    my @notifications = $user->opr_notifications;

    return if !@notifications;

    my $notification = first{ $_->notification_name eq 'new_comment' }@notifications;
    return if !$notification;
    
    if ( $notification->notification_type eq 'Mail' ) {
        my $template_name = 'comment_created';

        my $mailer = OTRS::OPR::Web::App::Mailer->new( $config );
        $mailer->prepare_mail(
            $template_name,
            USER => $user->user_name,
            TEXT => $comment->comments,
        );

        my $subject =
            $config->get( 'mail.tag' ) . ' ' .
            $config->get( 'mail.subjects.' . $template_name );
    
        my $success = $mailer->send_mail(
            to      => $user->mail,
            subject => $subject,
        );
    }    
};

1;
