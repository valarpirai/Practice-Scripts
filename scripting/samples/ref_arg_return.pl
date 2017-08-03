#!/usr/bin/perl

use perl_modules::common;
=sub ref_arg
{
	my $hash_ref = $_[0];
	$hash_ref->{'tst'} = "new_value";

	foreach (keys %{$hash_ref})
	{
		print $_, " : ", $hash_ref->{$_}, "\n";
	}
}


my %h = ();
$h{'tst'} = "old_value";
$h{'tst2'} = "2_value";
$h{'tst3'} = "3_value";
foreach (keys %h)
{
	print $_ ," : " ,$h{$_}, "\n";
}
print "Calling function here\n";
ref_arg(\%h);
print "Calling function here\n\n\n";

my %license = ();
my $sess;
get_license($sess, \%license);

foreach (keys %license)
{
        print $_ ," : " ,$license{$_}, "\n";
}
=cut

execute(load_config("207"));

$ssh = execute_ssh(login("192.168.1.207", "admin", "admin"));

my %config = ();

get_link_stats($ssh, \%config, $LINK0, "last_hour");

#print get_flow_summary($ssh, \%config, "last_hour");

#get_link_stats($ssh, \%config, $LINK0, "last_min");
#get_link_stats($ssh, \%config, $LINK0);
get_software_version($ssh, \%config);
foreach (sort keys %config)
{
        print $_ ," : " ,$config{$_}, "\n";
}
#Removing JUNK characters from the log file
#`cp $global_cfg{'log_file'} $global_cfg{'log_file'}test`;
#`strings $global_cfg{'log_file'}test -e s > $global_cfg{'log_file'}`;
#`rm -f $global_cfg{'log_file'}test`;
$ssh->soft_close();


my $subject = "Script Tests Finished for build # " . $config{"ver_current"};
my $body_text = "Please find attached output and log files for the build sanity test results.";
# send email after sanity test
print send_mail("$subject", "$body_text", "attach logs");

print_log($ANY, "Tests Completed\nLog file :  $global_cfg{'log_file'}\nOutput file : $global_cfg{'output_file'}");
print "Tests Completed\nLog file :  $global_cfg{'log_file'}\nOutput file : $global_cfg{'output_file'}\n";
print "Mail\nFrom : $global_cfg{'from_mail_id'}\nTo : $global_cfg{'to_mail_id'}. \n";
