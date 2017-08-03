#!/usr/bin/perl

use perl_modules::common;
use Getopt::Long;

my $bandwidth;
GetOptions("b=s" => \$bandwidth);

execute(load_config("228"));

my $appliance = execute_ssh(login("192.168.1.228", "admin", "admin"));

print $appliance "policy\nset policy flowrate_ply flowrate guaranteed $bandwidth\n";


unless($appliance->expect(5,"Updated policy flowrate_ply"))
{
	exit 0;
}
