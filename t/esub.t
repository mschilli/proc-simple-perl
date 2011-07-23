#!/usr/bin/perl -w

use Proc::Simple;

package EmptySubclass;
@ISA = qw(Proc::Simple);
1;


package Main;
use Test::More;
plan tests => 2;

###
### Empty Subclass test
###
$psh  = EmptySubclass->new();

ok($psh->start("sleep 10"));        # 1

while(!$psh->poll) { 
    sleep 1; }

ok($psh->kill());                   # 2

while($psh->poll) { 
    sleep 1; }

1;
