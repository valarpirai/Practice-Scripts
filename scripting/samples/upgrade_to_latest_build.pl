#!/usr/bin/perl

use perl_modules::common;

execute(load_config("207"));

# Login to appliance with default user and password
my $session = execute_ssh(login($cfg{"appliance_ip"}, $cfg{"appliance_username"}, $cfg{"appliance_password"}));

#my $session = execute_ssh(login("192.168.1.228", "root", "testpass"));


print $session "system\ndate\n\n";
execute(upgrade_to_latest_build(\$session));



#print $session "echo testing\n";
#print $session;
#print install_latest_build();

#print $session;
print "\nvalar test1\n";
print $session "system\ndate\n";
#print $session "echo testing\n";
print $session "show img\n";
$session->expect(100,"Factory");
print `date`;
#print $session;
print "\nvalar test\n";
