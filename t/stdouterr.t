#!/usr/bin/perl -w

use Proc::Simple;

$| = 1;
print "1..2\n";

sub test_output {
    print "hello stdout\n";
    print STDERR "hello stderr\n";
}

my $p = Proc::Simple->new();
$p->redirect_output ("stdout.txt", "stderr.txt");
$p->start(\&test_output);
while($p->poll()) {
}    

open FILE, "<stdout.txt" or die "Cannot open stdout.txt";
my $stdout = join '', <FILE>;
close FILE;

open FILE, "<stderr.txt" or die "Cannot open stderr.txt";
my $stderr = join '', <FILE>;
close FILE;

if($stderr eq "hello stderr\n") {
    print "ok 1\n";
} else {
    print "not ok 1 ($stderr)\n";
}

if($stdout eq "hello stdout\n") {
    print "ok 2\n";
} else {
    print "not ok 2\n";
}

unlink("stdout.txt", "stderr.txt");
