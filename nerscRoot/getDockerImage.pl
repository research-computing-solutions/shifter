#!/usr/bin/perl

use IO::Socket::INET;
use Getopt::Long;

my $dockergw_host = "128.55.50.83";
my $dockergw_port = "7777";
my $ret = 0;

my $verbosity_level=1;
my $quiet=FALSE;
my $verbose=FALSE;
my $help=FALSE;
my $username = undef;
my $password = undef;
my $image = undef;
my $registry = undef;
my $system = undef;
GetOptions('help|h!'       => \$help,
           'verbose|v!'    => \$verbose,
           'quiet|q!'      => \$quiet,
           'image|i=s'    => \$image,
           'username|u=s' => \$username,
           'password|p=s' => \$password,
           'registry|r=s' => \$registry,
           'system|s=s'   => \$system,
);

if ($verbose) {
    $verbosity_level += 1;
}
if ($quiet) {
    $verbosity_level -= 1;
}
if (!defined($image)) {
    if (scalar(@ARGV) != 1) {
        usage(1);
    }
    $image = $ARGV[0];
}
if ($image !~ /:/) {
    usage(1);
}
if (!defined($system)) {
    if (-e "/etc/clustername") {
        $system = `cat /etc/clustername`;
    }
}
if (!defined($system)) {
    print STDERR "Unknown system.\n";
    usage(1);
}

my $socket = new IO::Socket::INET (
    PeerHost => $dockergw_host,
    PeerPort => $dockergw_port,
    Proto => 'tcp',
) or die("Failed to connect to dockergw");
$socket->send("$image $system\n");
my $result = "";
while (<$socket>) {
    my $data = $_;
    $data =~ s/^s\+//g;
    $data =~ s/\s+$//g;
    if ($data =~ /^ID:\s+(\S+)$/) {
        $result = $1;
    }
    if ($data =~ /^ERR:\s+(.*)$/) {
        $result = $1;
        $ret = 1;
    }
}
$socket->close();
print "$result\n";
exit $ret;


sub usage {
    my $ret = shift;
    print "getDockerImage.pl takes exactly one argument - the docker image\n";
    exit $ret;
}
