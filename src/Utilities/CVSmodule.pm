=head1 NAME

Utilities::CVSmodule - A wrapper around CVS.

=head1 SYNOPSIS

	my $obj = Utilities::CVSmodule->new();

=head1 DESCRIPTION

Configure the CVSmodule object to access a CVS repository and then
invokecvs() commands as required.

=head1 METHODS

=over

=item C<new()>

A new cvs modules object.

=item C<set_base(base)>

Set a base from which to read (i.e server name/path).

=item C<set_auth(type)>

Set authentication method e.g pserver, kserver, ext etc.

=item C<set_user(username)>

Set a username for authentication if required.

=item C<set_passbase(file)>

Override the default CVS_PASSFILE for pserver client.

=item C<set_passkey(encrypted)>

For pserver method - set a password (encrypted).

=item C<invokecvs(@cmds)>

Invoke a cvs command supplied in @cmds.

=item C<repository()>

Return a string to indicate the repository.

=cut

=back

=head1 AUTHOR

Originally written by Christopher Williams.

=head1 MAINTAINER

Shaun ASHBY 

=cut

package Utilities::CVSmodule;
require Exporter;
use Utilities::AddDir;
require 5.004;
@ISA= qw(Exporter);

sub new {
	my $class=shift;
	my $self={};
	bless $self, $class;
	$self->{myenv}={};
 	$self->{cvs}='cvs';
	# Reset All variables
	$self->{auth}="";
	$self->{passkey}="";
	$self->{user}="";
	$self->{base}="";
	$self->set_passbase("/tmp/".$>."CVSmodule/.cvspass");
	return $self;
}

sub set_passbase {
	my $self=shift;
	my $file=shift;

	my $dir;
	($dir=$file)=~s/(.*)\/.*/$1/;
	AddDir::adddir($dir);
	$self->{passbase}=$file;
	$self->env("CVS_PASSFILE", $file);
}

sub set_passkey {
	use Utilities::SCRAMUtils;
	$self=shift;
	$self->{passkey}=shift;
	my $file=$self->{passbase};
	SCRAMUtils::updatelookup($file,
		$self->{cvsroot}." ", $self->{passkey});
	}

sub set_base {
	$self=shift;
	$self->{base}=shift;
	$self->_updatecvsroot();
}

sub get_base {
}

sub set_user {
	$self=shift;
	$self->{user}=shift;
	if ( $self->{user} ne "" ) {
	   $self->{user}= $self->{user}.'@';
	}
	$self->_updatecvsroot();
}
sub set_auth {
	$self=shift;
	$self->{auth}=shift;
	$self->{auth}=~s/^\:*(.*)\:*/\:$1\:/;
	
	$self->_updatecvsroot();
}

sub env {
	$self=shift;
	my $name=shift;
	$self->{myenv}{$name}=shift;
}

sub invokecvs {
	$self=shift;
	@cmds=@_;
	# make sure weve got the right environment
	foreach $key ( %{$self->{myenv}} ) {
	  $ENV{$key}=$self->{myenv}{$key};
	}
	# now perform the cvs command
	return ( system( "$self->{cvs}" ,"-Q", "-d", "$self->{cvsroot}", @cmds ));
}

sub _updatecvsroot {
	my $self=shift;
	$self->{cvsroot}=$self->{auth}.$self->{user}.$self->{base};
}

sub cvsroot {
	my $self=shift;
	return $self->{cvsroot};
}

sub repository {
	my $self=shift;
	return $self->{base};
}
