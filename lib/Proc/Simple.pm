
=head1 NAME

Proc::Simple -- launch and control background processes

=head1 SYNOPSIS

   use Proc::Simple;

   $myproc = Proc::Simple->new();        # Create a new process object

   $myproc->start("shell-command-line"); # Launch a shell process
   $myproc->start(sub { ... });          # Launch a perl subroutine
   $myproc->start(\&subroutine);         # Launch a perl subroutine

   $running = $myproc->poll();           # Poll Running Process

   $myproc->kill();                      # Kill Process (SIGTERM)


   $myproc->kill("SIGUSR1");             # Send specified signal


   Proc::Simple->debug($level);          # Turn debug on

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

=head1 NOTE

Please keep in mind that there is no guarantee that the SIGTERM
signal really terminates a process. Processes can have signal
handlers defined that avoid the shutdown.
If in doubt, whether a process still exists, check it
repeatedly with the I<poll> routine after sending the signal.

=head1 AUTHOR

Michael Schilli <schilli@tep.e-technik.tu-muenchen.de>

=cut

$VERSION = "1.12";
sub Version { $VERSION };

use strict;

package Proc::Simple;


my $Debug = 0;

###
### Proc::Simple->debug($level) - Turn debug on/off
###
sub debug { 
  $Debug = shift;
}

sub dprt {
  my $self = shift;

  print ref($self), "> @_\n" if $Debug;
}


###
### $proc_obj=Proc::Simple->new(); - Constructor
###
sub new { 
  my $class = shift;
  my $self  = {};
  bless($self, $class);
}

###
### $ret = $proc_obj->start("prg"); - Launch process
###                                   
sub start {
  my $self  = shift;
  my $func  = shift;

  # Reap Zombies automatically
  $SIG{'CHLD'} = sub { wait(); };

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


###
### $ret = $proc_obj->poll(); - Check process status
###                             1="running" 0="not running"
###
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


### 
### $ret = $proc_obj->kill([SIGXXX]); - Send signal to process
###                                     Default-Signal: SIGTERM
sub kill
{ 
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

1;

__END__
