######################################################################
package Proc::Simple;
######################################################################
# Copyright 1996-1999 by Michael Schilli, all rights reserved.
#
# This program is free software, you can redistribute it and/or 
# modify it under the same terms as Perl itself.
#
# The newest version of this module is available on
#     http://perlmeister.com/CPAN/procsimple
# or on your favourite CPAN site under
#     CPAN/modules/by-author/id/MSCHILLI
#
######################################################################

=head1 NAME

Proc::Simple -- launch and control background processes

=head1 SYNOPSIS

   use Proc::Simple;

   $myproc = Proc::Simple->new();        # Create a new process object

   $myproc->start("shell-command-line"); # Launch a shell process
   $myproc->start(sub { ... });          # Launch a perl subroutine
   $myproc->start(\&subroutine);         # Launch a perl subroutine

   $running = $myproc->poll();           # Poll Running Process

   $proc->kill_on_destroy(1);            # Set kill on destroy
   $proc->signal_on_destroy("KILL");     # Specify signal to be sent
                                         # on destroy

   $myproc->kill();                      # Kill Process (SIGTERM)



   $myproc->kill("SIGUSR1");             # Send specified signal


   Proc::Simple::debug($level);          # Turn debug on

=head1 DESCRIPTION

The Proc::Simple package provides objects that model real-life
processes from a user's point of view. A new process object is created by

   $myproc = Proc::Simple->new();

Either shell-like command lines or references to perl
subroutines can be specified for launching a process in background.
A 10-second sleep process, for example, can be started via the
shell as

   $myproc->start("sleep 10");

or, as a perl subroutine, with

   $myproc->start(sub { sleep(10); });

The I<start> Method returns immediately after starting the
specified process in background, i.e. non-blocking mode.
It returns I<1> if the process has been launched
sucessfully and I<0> if not.

The I<poll> method checks if the process is still running

   $running = $myproc->poll();

and returns I<1> if it is, I<0> if it's not. Finally, 

   $myproc->kill();

terminates the process by sending it the SIGTERM signal. As an
option, another signal can be specified.

   $myproc->kill("SIGUSR1");

sends the SIGUSR1 signal to the running process. I<kill> returns I<1> if
it succeeds in sending the signal, I<0> if it doesn't.

The methods are discussed in more detail in the next section.

A destructor is provided so that the forked processes can be
sent a signal automatically should the perl object be
destroyed or if the perl process exits. By default this
behaviour is turned off (see the kill_on_destroy and
signal_on_destroy methods).

=cut

require 5.003;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA     = qw(Exporter AutoLoader);
@EXPORT  = qw( );
$VERSION = '1.13';

######################################################################
# Globals: Debug and the mysterious waitpid nohang constant.
######################################################################
my $Debug = 0;
my $WNOHANG = get_system_nohang();

######################################################################

=head1 METHODS

The following methods are available:

=over 4

=item new

Create a new instance of this class

  $proc = new Proc::Simple;

Takes no arguments.

=cut

######################################################################
# $proc_obj=Proc::Simple->new(); - Constructor
######################################################################
sub new { 
  my $class = shift;
  my $self  = {};
  
  # Init instance variables
  $self->{'kill_on_destroy'}   = undef;
  $self->{'signal_on_destroy'} = undef;
  $self->{'pid'}               = undef;

  bless($self, $class);
}

######################################################################

=item start

Launch new process.

 $status = $proc->start("prg");

The I<start> Method returns immediately after starting the
specified process in background, i.e. non-blocking mode.
It returns I<1> if the process has been launched
sucessfully and I<0> if not.

=cut

######################################################################
# $ret = $proc_obj->start("prg"); - Launch process
######################################################################
sub start {
  my $self  = shift;
  my $func  = shift;

  # Reap Zombies automatically
  $SIG{'CHLD'} = \&THE_REAPER;

  # Fork a child process
  if(($self->{'pid'}=fork()) == 0) { # Child
      if(ref($func) eq "CODE") {
	  &$func; exit 0;            # Start perl subroutine
      } else {
          exec "$func";              # Start Shell-Process
      }
  } elsif($self->{'pid'} > 0) {      # Parent:
      $self->dprt("START($self->{'pid'})");
      return 1;                      #   return OK
  } else {                           # Fork Error:
      return 0;                      #   return Error
  }
}

######################################################################

=item poll

The I<poll> method checks if the process is still running

   $running = $myproc->poll();

and returns I<1> if it is, I<0> if it's not.

=cut

######################################################################
# $ret = $proc_obj->poll(); - Check process status
#                             1="running" 0="not running"
######################################################################
sub poll {
  my $self = shift;

  if(exists($self->{'pid'})) {
      if(kill(0, $self->{'pid'})) {
          $self->dprt("POLL($self->{'pid'}) RESPONDING");
	  return 1;
      } else {
          $self->dprt("POLL($self->{'pid'}) NOT RESPONDING");
      }
  } else {
     $self->dprt("POLL(NOT DEFINED)");
  }

  0;
}

######################################################################

=item kill

The kill() method:

   $myproc->kill();

terminates the process by sending it the SIGTERM signal. As an
option, another signal can be specified.

   $myproc->kill("SIGUSR1");

sends the SIGUSR1 signal to the running process. I<kill> returns I<1> if
it succeeds in sending the signal, I<0> if it doesn't.

=cut

######################################################################
# $ret = $proc_obj->kill([SIGXXX]); - Send signal to process
#                                     Default-Signal: SIGTERM
######################################################################
sub kill { 
  my $self = shift;
  my $sig  = shift;

  # If no signal specified => SIGTERM-Signal
  $sig = "SIGTERM" unless defined $sig;

  # Process initialized at all?
  return 0 if !exists $self->{'pid'};

  # Send signal
  if(kill($sig, $self->{'pid'})) {
      $self->dprt("KILL($self->{'pid'}) OK");
  } else {
      $self->dprt("KILL($self->{'pid'}) failed");
      return 0;
  }

  1;
}

=item kill_on_destroy

Set a flag to determine whether the process attached
to this object should be killed when the object is
destroyed. By default this flag is set to true.
The current value is returned.

  $current = $proc->kill_on_destroy;
  $proc->kill_on_destroy(1); # Set flag to true
  $proc->kill_on_destroy(0); # Set flag to false

=cut

######################################################################

=item kill_on_destroy

Set a flag to determine whether the process attached
to this object should be killed when the object is
destroyed. By default this flag is set to true.
The current value is returned.

  $current = $proc->kill_on_destroy;
  $proc->kill_on_destroy(1); # Set flag to true
  $proc->kill_on_destroy(0); # Set flag to false

=cut

######################################################################
# Method to set the kill_on_destroy flag
######################################################################
sub kill_on_destroy {
    my $self = shift;
    if (@_) { $self->{kill_on_destroy} = shift; }
    return $self->{kill_on_destroy};
}

######################################################################

=item signal_on_destroy

Method to set the signal that will be sent to the
process when the object is destroyed (Assuming
kill_on_destroy is true). Returns the current setting.

  $current = $proc->signal_on_destroy;
  $proc->signal_on_destory("KILL");

=cut

######################################################################
# Send a signal on destroy
# undef means send the default signal (SIGTERM)
######################################################################
sub signal_on_destroy {
    my $self = shift;
    if (@_) { $self->{Sig_on_destroy} = shift; }
    return $self->{Sig_on_destroy};
}

######################################################################

=item pid

Returns the pid of the forked process associated with
this object

  $pid = $proc->pid;

=cut

######################################################################
sub pid {
######################################################################
  my $self = shift;

  # Allow the pid to be set - assume this is only
  # done internally so don't document this behaviour in the
  # pod.
  if (@_) { $self->{'pid'} = shift; }
  return $self->{'pid'};
}

######################################################################

=item DESTROY

Object destructor. This method is called when the
object is destroyed (eg with "undef" or on exiting
perl). If kill_on_destroy is true the process
associated with the object is sent the signal_on_destroy
signal (SIGTERM if undefined).

=cut

######################################################################
# Destroy method
# This is run automatically on undef
# Should probably not bother if a poll shows that the process is not
# running.
######################################################################
sub DESTROY {
    my $self = shift;

    # If the kill_on_destroy flag is true then
    # We need to send a signal to the process
    if ($self->kill_on_destroy) {
        $self->dprt("Kill on DESTROY");
        if (defined $self->signal_on_destroy) {
            $self->kill($self->signal_on_destroy);
        } else {
            $self->kill;
        }
    }
}

######################################################################
# Reaps processes, uses the magic WNOHANG constant
######################################################################
sub THE_REAPER {

    my $child;

    if(defined $WNOHANG) {
        while (0 < ($child = waitpid(-1, $WNOHANG))) {
            dprt("", "Reaper: $child");
        }
    } else { 
        wait();
    }

    # Reset signal handler for crappy sysV systems
    $SIG{'CHLD'} = \&THE_REAPER;
}

######################################################################

=item debug

Switches debug messages on and off -- Proc::Simple::debug(1) switches
them on, Proc::Simple::debug(0) keeps Proc::Simple quiet.

=cut

# Proc::Simple::debug($level) - Turn debug on/off
sub debug { $Debug = shift; }

######################################################################
# Internal debug print function
######################################################################
sub dprt {
  my $self = shift;
  print ref($self), "> @_\n" if $Debug;
}

######################################################################
sub get_system_nohang {
######################################################################
# This is for getting the WNOHANG constant of the system -- but since
# the waitpid(-1, &WNOHANG) isn't supported on all Unix systems, and
# we still want Proc::Simple to run on every system, we have to 
# quietly perform some tests to figure out if -- or if not.
# The function returns the constant, or undef if it's not available.
######################################################################
    my $nohang;

    open(SAVEERR, ">&STDERR");

       # If the system doesn't even know /dev/null, forget about it.
    open(STDERR, ">/dev/null") || return undef;
       # Close stderr, since some weirdo POSIX modules write nasty
       # error messages
    close(STDERR);

       # Check for the constant
    eval 'use POSIX ":sys_wait_h"; $nohang = &WNOHANG;';

       # Re-open STDERR
    open(STDERR, ">&SAVEERR");
    close(SAVEERR);

        # If there was an error, return undef
    return undef if $@;

    return $nohang;
}

1;

__END__

=head1 NOTE

Please keep in mind that there is no guarantee that the SIGTERM
signal really terminates a process. Processes can have signal
handlers defined that avoid the shutdown.
If in doubt, whether a process still exists, check it
repeatedly with the I<poll> routine after sending the signal.

=head1 Requirements

I'd recommend using at least perl 5.003 -- if you don't have 
it, this is the time to upgrade! Get 5.005_02 or better.

=head1 AUTHORS

Michael Schilli <michael@perlmeister.com>

Tim Jenness  <t.jenness@jach.hawaii.edu>
   did kill_on_destroy/signal_on_destroy

=cut
