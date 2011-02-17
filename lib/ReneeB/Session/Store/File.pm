package ReneeB::Session::Store::File;

use strict;
use warnings;
use Tie::File;

my $file = 'test.sessions';

sub new{
    my ($class, $args) = @_;
    my $self    = bless {}, $class;
    
    return $self;
}

sub save{
    my ($self, $id) = @_;
    
    if( open my $save, '>>', $file ){
        print $save $id,"#",time,"\n";
        close $save;
    }
}

sub get{
    my ($self,$id) = @_;
    
    my ($tmp_id,$time);
    
    if(tie my @sessions, 'Tie::File', $file){
        for my $session ( @sessions ){
            next unless $session =~ /^\Q$id\E#/;
            my $tmp = $session;
            chomp $tmp;
            ($tmp_id, $time) = split /#/, $tmp;
        }
        untie @sessions;
    }
    
    return ($tmp_id, $time);
}

sub update{
    my ($self,$id) = @_;
    
    if(tie my @sessions, 'Tie::File', $file){
        for my $session ( @sessions ){
            next unless $session =~ /^\Q$id\E#/;
            my ($tmp_id) = split /#/, $session;
            $session = sprintf "%s#%s\n", $tmp_id, time;
            last;
        }
        untie @sessions;
    }
}

sub delete_id{
    my ($self,$id) = @_;
    
    if(tie my @sessions, 'Tie::File', $file){
        my $counter = $#sessions;
        for my $session ( reverse @sessions ){
            next unless $session =~ /^\Q$id\E#/;
            splice @sessions, $counter,1;
            last;
        }
        untie @sessions;
    }
}

sub delete_old{
    my ($self,$expire) = @_;
    
    if(tie my @sessions, 'Tie::File', $file){
        my $counter = $#sessions;
        for my $session ( reverse @sessions ){
            my $tmp    = $session;
            chomp $tmp;
            my ($tmp_id,$time) = split /#/, $tmp;
            unless( $time and $tmp_id and time <= ($time + $expire) ){
                splice @sessions, $counter,1;
            }
            $counter--;
        }
        untie @sessions;
    }
}

1;