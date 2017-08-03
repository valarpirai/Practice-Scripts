#!/usr/bin/perl

use perl_modules::common;
use Expect;

sub get_latest_version
{
	$build_url_base = $global_cfg{'intel_latset_build_url'};
	`rm latest_build*; > /dev/null 2>&1`;
	`wget -q --user=guest --password=testpass $build_url_base --no-check-certificate --output-document latest_build.html`;
	$eagle_rpm_name=`cat latest_build.html | grep -re "eagle-x86-.*x86_64.rpm"`; 
	$start = index($eagle_rpm_name,"eagle");
	$end = index($eagle_rpm_name,"\">eagle");
	
	return substr($eagle_rpm_name,$start,($end - $start));
}

load_config("");
$latest_ver = get_latest_version();

my $session = execute_ssh(login("192.168.1.206","root","testpass"));

execute(download_latest_build($session,$latest_ver));


sub download_latest_build
{
	my ($session, $build_name) = @_;
	
	my $latest_build_url = $global_cfg{'intel_latset_build_url'}."".$build_name;
	
	$session->log_stdout(1);
	
	$session->log_file('/tmp/log');
	
	print $session "wget -q --user=guest --password=testpass $latest_build_url --no-check-certificate --output-document /tmp/$build_name\n";
	
	$session->expect(5, "root");
	
	print $session "scp /tmp/$build_name root\@192.168.1.228:/tmp\n";
	
	if($session->expect(5, "yes\/no"))
	{
		print $session "yes\n";
	}
	unless($session->expect(20,"password:"))
	{
		return "Timed out when waiting for password : SCP\n";
	}

	print $session "testpass\n";
	
	unless($session->expect(300,"root"))
	{
		return $FAIL;
	}
	print "\n";	
	return $SUCCESS;
}
