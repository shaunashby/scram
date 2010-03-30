=head1 NAME

Utilities::Message - Hold a multi level message that can be reconstructed to any level.

=head1 SYNOPSIS

	my $obj = Utilities::Message->new();

=head1 DESCRIPTION

Hold a multi level message that can be reconstructed to any level.

=head1 METHODS

=over

=cut

=item C<new()>

   A new Message object.
   
=item C<setlevel([level_number])>

   Set the current level to which messages can be assigned.

=item C<message(string)>

   Set a new message at the current level.

=item C<read([level])>

   Return list of all messages up to level n (or current assignment level).
   
=item C<readlevel(level)>

   Read only those messages assigned to the given level.

=item C<copy(Message)>

   Copy the messages from one object to the current,
   starting at the current active level.
   
=item C<levels()>

   Return the number of assignment levels.

=back

=head1 AUTHOR

Originally Written by Christopher Williams.
   
=head1 MAINTAINER

Shaun ASHBY 

=cut

package Utilities::Message;
require 5.004;

sub new {
	my $class=shift;
	$self={};
	bless $self, $class;
	$self->{max}=0;
	$self->setlevel(0);
	$self->{messages}=();
	return $self;
}

sub setlevel {
	my $self=shift;
		
	if ( @_ ) {
	  $self->{aslevel}=shift
	}
	else {
	  $self->{aslevel}++;
	}
	if ( $self->{aslevel} > $self->{max} ) { $self->{max}++ }
}

sub levels {
	my $self=shift;
	return $self->{max};
}

sub message {
	my $self=shift;
	my $message=shift;

	push @{$self->{messages}}, $message;
	push @{$self->{messagelevel}}, $self->{aslevel};
}
 
sub read {
	my $self=shift;

	my $lev;
	if (@_) { $lev=shift }
	else { $lev=$self->{aslevel} }
	my @messages=();
	for ( my $i=0; $i<=$#{$self->{messages}}; $i++) {
	 if ( $self->{messagelevel}[$i] <= $lev ) {
	    push @messages, $self->{messages}[$i];
	 }
	}
	return @messages;
}

sub readlevel {
	my $self=shift;

	my @messages=();
	my $lev;
	if (@_) { $lev=shift }
	else { $lev=$self->{aslevel} }

	for ( my $i=0; $i<=$#{$self->{messages}}; $i++) {
	 if ( $self->{messagelevel}[$i] eq $lev ) {
	    push @messages, $self->{messages}[$i];
	 }
	}
	return @messages;
}

sub copy {
	my $self=shift;
	my $obj=shift;

	my $currentlev=$self->{aslevel};
	for ( my $i=0; $i<=$obj->levels(); $i++) {
	  foreach $mes ( $obj->readlevel($i) ) {
	    $self->message($mes);
	  }
	  $self->setlevel();
	}
	$self->setlevel($currentlev);
}

