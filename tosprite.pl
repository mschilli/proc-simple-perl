#!/usr/bin/perl -w

use Net::FTP;

$dir      = "HTML/devel";
$host     = "sprite.netnation.com";

$ftp = Net::FTP->new($host, Timeout => 60) || 
    die "Cannot connect: $host";

$ftp->login("perlmeis", "zztop2121") || die "Login failed";

$ftp->cwd($dir) || die "Directory $dir doesn't exist";
$ftp->binary();
$ftp->put("Proc-Simple-1.14.tar.gz") || die "Cannot put";

$ftp->quit();
