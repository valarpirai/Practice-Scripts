#!/usr/bin/perl
use perl_modules::common;
use Getopt::Long;
use perl_modules::regression;

my $appl_name;

# Parsing the command line arguments
GetOptions("appl_name|a=s" => \$appl_name);
unless ($appl_name)
{
	print "Please provide the appliance name.. Which appliance?\n";
	exit;
}

# Loading the configurations from file
execute(load_config($appl_name));

# Login to appliance with default user and password
my $appliance = execute_ssh(login($cfg{"appliance_ip"}, $cfg{"appliance_username"}, $cfg{"appliance_password"}));

=pod
print $appliance "system\nshow img\n";
print "Upgrade " . upgrade_to_latest_build(\$appliance) . "\n";
print $appliance "system\nshow img\n";
sleep (10);
print "Rollback " . rollback_image(\$appliance) . "\n";
=cut

policy_context($appliance);

# Closing the sessions
print $appliance "logout\n";
$appliance->soft_close();

#Removing JUNK characters from the log file
`cp $global_cfg{'log_file'} $global_cfg{'log_file'}test`;
`strings $global_cfg{'log_file'}test > $global_cfg{'log_file'}`;
`rm -f $global_cfg{'log_file'}test`;
