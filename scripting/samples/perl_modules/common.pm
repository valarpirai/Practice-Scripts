package perl_modules::common;

use Expect;
use strict;
use base 'Exporter';
use MIME::Lite;
use IO::Socket::INET;

# Add the function names in the following to make the function accessible
# from the pl files
our @EXPORT = qw(
%cfg 
%global_cfg 
$SUCCESS
$FAIL
$YES
$NO
$LOG
$ALL
$OUT
$ANY
$LINK0
$LINK1
login 
load_config
execute
execute_not
execute_ssh
wait_till_up
get_license
is_discovery_on
is_shaping_on
is_bypass_on
get_class_stats
print_log
get_class_count
get_policy_count
get_filter_count
create_pattern
create_class
create_policy
set_wan_speed
set_class_limit
set_flow_limit
set_pattern_limit
set_policy_limit
upgrade_to_latest_build
install_latest_build
start_iperf_server
start_iperf_client
get_link_stats
get_flow_summary
rollback_image
get_software_version
assign_policy
change_policy
set_pipe
set_shaping_on
set_shaping_off
delete_classes
delete_policies
get_date
collect_dpconsole_output
start_iperf_clients
scp_file
app_sync
ping_test_from_server
ping_test_from_client
ping
unassign_policy
killall
parse_input_from_file
create_adagent
delete_adagent
collect_class_stats
send_mail
get_local_ip_address
add_user
change_password
delete_user
trim 
);

# Global variables
our (%cfg, %global_cfg, $SUCCESS, $FAIL, $YES, $NO, $LOG, $OUT, $ALL, $ANY, $LINK0, $LINK1);
%cfg = ();
%global_cfg = ();
$SUCCESS = "success";
$FAIL = "fail";
$YES = "0";
$NO = "1";
$LOG = "LOG";
$OUT = "OUT";
$ALL = "ALL";
$ANY = "ANY";

$LINK0 = "link0";
$LINK1 = "link1";

#Local Variables
my $delim = "\\|";
my $timeout = 3;
my $sleeptime = 3;
my $shorttimeout = 1;
#-------------------------------------------------------------------------------

=login
	This function is used to do a ssh login and return the session
	if not able to login, it will return undef
	On successful login, it returns the login ssh session

params:
	ip_addr
	username
	password
eg:
	login("192.168.1.x","username","password")
=cut
sub login
{
	my ($ip_addr, $username, $password) = @_;

	# SSH login to the appliance
	my $spawn;
	unless($spawn=Expect->spawn("ssh $username\@$ip_addr"))
	{
		print_log($LOG, "Not able to login to $ip_addr\n");
		return undef;
	}

	# Adding the log file name
	$spawn->log_file($global_cfg{"log_file"});

	# Controlling the prints of ssh session in screen
	if ($global_cfg{"print_in_screen"} eq $YES) 
	{
		$spawn->log_stdout(1);
	}else 
	{
		$spawn->log_stdout(0);
	}

	# If its first time login, it needs confirmation for adding to known hosts
	if($spawn->expect($timeout, '-re','.*\(yes\/no\).*'))
	{
		print $spawn "yes\n";
	}

	if ($spawn->expect(50, '-re','.*password:.*'))
	{
		$spawn->send("$password\r");
		
			#This code will handle any errors after the password is sent
		unless($spawn->expect(30, '-re', '.*[#$>]')) 
		{
			if($spawn->before() =~ /(Permission.*\s*.*)/) 
			{
				print_log($LOG, "\nInvalid password for $ip_addr\n");
			} else 
			{
				print_log($LOG, "Connection timed out after providing password\n");
			}
			return undef;
		}
	}
	else
	{
		unless($spawn->expect(50,"Last login:"))
		{
			print_log($LOG, "Timed out when waiting for password for SSH\n");
			return undef;
		}
	}

	print_log($LOG, "Successfully login to the machine ($ip_addr) as $username\n");
	return $spawn;
}

#-------------------------------------------------------------------------------

=load_config
	To load the given configurations from the config file
params:
	filename - name of the configuration file
eg:
	load_config("210");  -- sys_config/<filename>.cfg
=cut
sub load_config
{
	my ($config_filename) = @_;

	$config_filename = "sys_config/$config_filename.cfg";
	%global_cfg = do "other_config/global.cfg";

	# Changing the log filename and output filename
	my $test_start_time = `date +"%F-%H:%M:%S"`;
	chomp($test_start_time);
	$global_cfg{"log_file"} = $global_cfg{"log_file"} . "_" . $test_start_time;
	$global_cfg{"output_file"} = $global_cfg{"output_file"} . "_"  . $test_start_time;

	print_log($ANY, "Started testing at $test_start_time");

	unless ( -e $config_filename)
	{
		return "Configuration file missing!\nPlease create a configuration for appliance $_[0]\n";
	}

	%cfg = do $config_filename;

	print_log($LOG, "Loaded the configurations of $config_filename");
	return $SUCCESS;
}

#-------------------------------------------------------------------------------

=execute
	This function is used to execute a function and handle its return code
	based on the global configurations, it will take the appropriate function
params:
	return code of a functions
eg:
	execute(func());
=cut
sub execute
{
	my ($ret) = @_;

#TODO: Handle Crash of CLI

	if ($ret ne $SUCCESS) 
	{
		if ($global_cfg{"exit_if_error"} eq $YES)
		{
			print_log($ALL, "FAIL");
			print_log($LOG, "Exiting due to error : $ret");
			print "\nLog file : " . $global_cfg{"log_file"};
			print "\nOutput file : " . $global_cfg{"output_file"}."\n";
			send_mail("Test Failed", "Please find the attached log files\n", "attach logs");
			exit; 
		}
		print_log($LOG, "Error Occured : $ret");
	}
	
	return $ret;
}

#-------------------------------------------------------------------------------
sub execute_not
{
	my ($ret) = @_;

#TODO: Handle Crash of CLI

	if ($ret eq $SUCCESS) 
	{
		if ($global_cfg{"exit_if_error"} eq $YES)
		{
			print_log($ALL, "FAIL");
			print_log($ANY, "Exiting due to command success : $ret");
			exit; 
		}
		print_log($ANY, "Error due to successful completion of command : $ret");
	}
	
	return $ret;
}

#-------------------------------------------------------------------------------

=execute_ssh
	This function is used to execute a function and handle its return code
	based on the global configurations, it will take the appropriate function
params:
	return code of a functions
eg:
	execute_ssh(func());
=cut
sub execute_ssh
{
	my ($ret) = @_;

	if (not defined $ret) 
	{
		print_log($ALL, "\n\n*****  SSH Login error *****\n\n");
		if ($global_cfg{"exit_if_error"} eq $YES)
		{
			print_log($LOG, "Exiting due to error in SSH login");
			exit; 
		}
	}

	return $ret;
}

#-------------------------------------------------------------------------------

sub wait_till_up
{
	my ($ip_addr, $max_timeout) = @_;
	my $error;

	if ($max_timeout < 10)
	{
		$max_timeout = 10;
	}

	my $time_out = 5;
	my $loop_count = $max_timeout / $time_out;

	my $local_appliance = Expect->new();

	# Adding the log file name
	$local_appliance->log_file($global_cfg{"log_file"});

	if ($global_cfg{"print_in_screen"} eq $YES) 
	{
		$local_appliance->log_stdout(1);
	}else 
	{
		$local_appliance->log_stdout(0);
	}
	for (my $i = 0; $i < $loop_count; $i++)
	{
		print $local_appliance `ping $ip_addr -c 1`;
		if ($local_appliance->expect($time_out, "64 bytes from $ip_addr"))
		{
			return $SUCCESS;
		}
	}

	$error = "Time out - $ip_addr is not up for $max_timeout seconds\n";
	return $error;
}

#-------------------------------------------------------------------------------

sub get_license
{
	my ($session, $lic_ref) = @_;
	my $error;
    my $cmd = "system\nconfig license\n";
    print_log($LOG, "CMD : $cmd");
	print $session "$cmd\n";
	
=expected licence output
	----------------------------------------------------------------------------------------------------------------------------------
	Customer Id    |Key                  |Mac Address      |Link Speed|Links|Features   |Classes| Flows |Policies|Expiry    |Active |
	----------------------------------------------------------------------------------------------------------------------------------
	210_sigl        |BV8QD6-7PHVYN-G47PLC-|00:25:90:55:36:A3|4.0 Mbps  |1    |Monitoring,|1024   |20000  |256     |07-25-2013|No     |
                |4JW6PQ-QVS6Y3-XLZKWA |                 |          |     |TM         |       |       |        |          |       |
	----------------------------------------------------------------------------------------------------------------------------------
=cut
	unless($session->expect($shorttimeout,"Customer Id    \|Key                  \|Mac Address      \|Link Speed\|Links\|Features   \|Classes\| Flows \|Policies\|Expiry    \|Active \|"))
	{
		$error = "Trying to get license - No License Available";
		print_log($LOG, $error);
		return $error;
	}
	my @lic_output = split("\n",$session->after());
		
	my @first_line = split($delim, @lic_output[2]);
	my @second_line = split($delim, @lic_output[3]);

	$lic_ref->{'lic_customer_id'} = trim(@first_line[0]);
	$lic_ref->{'lic_key'} = trim(@first_line[1]).trim(@second_line[1]);
	$lic_ref->{'lic_mac_addr'} = trim(@first_line[2]);
        
	my @bandwidth = split(' ',trim(@first_line[3]));
	my $link_speed = 0;
	if(@bandwidth[1] eq "Mbps")
	{
		$link_speed = int(trim(@first_line[3])) * 1000;
	}elsif(@bandwidth[1] eq "Gbps")
	{
		$link_speed = int(trim(@first_line[3])) * 1000 * 1000;
	}else
	{
		$link_speed = int(trim(@first_line[3]));
	}
	$lic_ref->{'lic_link_speed_kbps'} = "$link_speed";
	$lic_ref->{'lic_links_count'} = int(trim(@first_line[4]));
	$lic_ref->{'lic_dual_link'} = $NO;
	if(int(trim(@first_line[4])) > 1)
	{
		$lic_ref->{'lic_dual_link'} = $YES;
	}
	if(trim(@first_line[5]) eq "Monitoring,")
	{
		$lic_ref->{'lic_enabled_monitoring'} = $YES;
	}else
	{
		$lic_ref->{'lic_enabled_monitoring'} = $NO;
	}
		
	if(trim(@second_line[5]) eq "TM")
	{
		$lic_ref->{'lic_enabled_traffic_management'} = $YES;
	}else
	{
		$lic_ref->{'lic_enabled_traffic_management'} = $NO;
	}
		
	$lic_ref->{'lic_max_classes'} = trim(@first_line[6]);
	$lic_ref->{'lic_max_flows'} = trim(@first_line[7]);
	$lic_ref->{'lic_max_policies'} = trim(@first_line[8]);
	$lic_ref->{'lic_expiry_date'} = trim(@first_line[9]);
        
	if(trim(@first_line[10]) eq "Yes")
	{
		$lic_ref->{'lic_active'} = $YES;
	}else
	{
		$lic_ref->{'lic_active'} = $NO;
	}

	return $SUCCESS;
} 

#-------------------------------------------------------------------------------

sub get_config
{
	my ($session, $sys_config_ref)= @_;
	my $cmd = "system\nshow config\n";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	$session->expect($shorttimeout,"Displaying system configurations");
	my @config_output = split("\n",$session->after());
	
	my @discovery_line = split($delim, @config_output[4]);
	my @shaping_line = split($delim, @config_output[5]);
	my @bypass_line = split($delim, @config_output[6]);
	
	#Initializing Default Values to off ($NO)
	$sys_config_ref->{'enabled_discovery'} = $NO;
	$sys_config_ref->{'enabled_shaping'} = $NO;
	$sys_config_ref->{'enabled_bypass'} =$NO;
	
	if(trim(@discovery_line[2]) eq "on")
	{
		$sys_config_ref->{'enabled_discovery'} = $YES;
	}
	
	if(trim(@shaping_line[2]) eq "on")
	{
		$sys_config_ref->{'enabled_shaping'} = $YES;
	}
	
	if(trim(@bypass_line[2]) eq "on")
	{
		$sys_config_ref->{'enabled_bypass'} = $YES;
	}	
	
	return $SUCCESS;
}

#-------------------------------------------------------------------------------

sub is_discovery_on
{
	my ($session) = @_;
	my %config = ();
	
	get_config($session,\%config);
	
	if($config{'enabled_discovery'} eq $YES)
	{
		print_log($LOG, "Checking for discovery status - Discovery ON");
		return $SUCCESS;
	}else
	{
		print_log($LOG, "Checking for discovery status - Discovery OFF");
		return undef;
	}
}

#-------------------------------------------------------------------------------

sub is_shaping_on
{
	my $session = $_[0];
	my %config = ();
	
	get_config($session,\%config);
	
	if($config{'enabled_shaping'} eq $YES)
	{
		print_log($LOG, "Checking for shaping status - Shaping ON");
		return $SUCCESS;
	}else
	{
		print_log($LOG, "Checking for shaping status - Shaping OFF");
		return undef;
	}
}

#-------------------------------------------------------------------------------
sub is_bypass_on
{
	my $session = $_[0];
	my %config = ();
	
	get_config($session,\%config);
	
	if($config{'enabled_bypass'} eq $YES)
	{
		print_log($LOG, "Checking for bypass status - Bypass ON");
		return $SUCCESS;
	}else
	{
		print_log($LOG, "Checking for bypass status - Bypass OFF");
		return undef;
	}
}


#-------------------------------------------------------------------------------
=get_class_stats
	This function returns the class stats of a specified class
	params(At the end * - means mandatory param):
		session - session where to execute the command. *
		%hash reference - to hold the stats of the class. *
		class name - name of the class. *
		window - Time duration like last_min, last_hour, last_day (Default : last_min).
		link name - Name of the link, the owner of class (Default : link0).
	ex.
	   get_class_stats($session,\%hash,"HTTP","last_min","link0");
=cut
sub get_class_stats
{
	my($session, $stats_ref, $class, $window, $link, $start, $end) = @_;
	my $error;
	
	#check what are all the parameters sent
	unless(defined $session)
	{
		return "Session is Mandatory param\n";
	}
	
	unless(defined $stats_ref)
	{
		return "Hash reference is Mandatory param\n";
	}
	
	unless(defined $class)
	{
		return "Class name is Mandatory param\n";
	}
		
	if(defined $window)
	{
		$window = " window: $window ";
	}
	else
	{
		$window = "";
	}
	
	unless(defined $link)
	{
		$link = $LINK0;
	}
	
	if(defined $start)
	{
		$start = "starttime: $start ";
	}
	else
	{
		$start = "";
	}
	
	if(defined $end)
	{
		$end = "endtime: $end ";
	}
	else
	{
		$end = "";
	}
	my $cmd = "show stats class $class " . $start . $end . "link: $link". $window."verbose\n";
	print_log($LOG, "CMD : $cmd");
	$cmd = "app\n" . $cmd;
	print $session "$cmd";
	
	# Expecting the starting header
	unless($session->expect($timeout, "-re", "show stats class $class.*\n-+\n\|Name.*Avg\. Flows.*Rx Bytes.*Tx Bytes.*Rx Kbps.*\n-.*"))
	{
		return "Not able to get the $cmd output\n";
	}

	# Expecting the ending header
	unless($session->expect($timeout, "-re", "^[-]+"))
	{
		return "Not able to get end of $cmd output\n";
	}
	
	unless($session->before())
	{
		return "Unexpected Error\n";
	}
	my @stats_output = split("\n",$session->before());

	unless(@stats_output[1] || @stats_output[2])
	{
		return "There is no class stats available for $class.\n"
	}
	
	my @in_line = split($delim, @stats_output[1]);
	my @out_line = split($delim, @stats_output[2]);
		
	my @rejects_line = split($delim, @stats_output[6]);
	my @queue_full_line = split($delim, @stats_output[7]);
	my @admission_line = split($delim, @stats_output[8]);
	
	$stats_ref->{'cs_class_name'} = $class;
	$stats_ref->{'cs_window'} = $window;
	$stats_ref->{'cs_link'} = $link;
	
	$stats_ref->{'cs_in_flow_count'} = trim(@in_line[2]);
	$stats_ref->{'cs_in_rx_bytes'} = trim(@in_line[3]);
	$stats_ref->{'cs_in_tx_bytes'} = trim(@in_line[4]);
	$stats_ref->{'cs_in_rx_kbps'} = trim(@in_line[5]);
	$stats_ref->{'cs_in_tx_kbps'} = trim(@in_line[6]);
	
	$stats_ref->{'cs_out_flow_count'} = trim(@out_line[2]);
	$stats_ref->{'cs_out_rx_bytes'} = trim(@out_line[3]);
	$stats_ref->{'cs_out_tx_bytes'} = trim(@out_line[4]);
	$stats_ref->{'cs_out_rx_kbps'} = trim(@out_line[5]);
	$stats_ref->{'cs_out_tx_kbps'} = trim(@out_line[6]);
	
	$stats_ref->{'cs_rejects_drop_count'} = trim(@rejects_line[3]);
	$stats_ref->{'cs_queue_full_drop_count'} = trim(@queue_full_line[3]);
	$stats_ref->{'cs_admission_drop_count'} = trim(@admission_line[3]);
	
	return $SUCCESS;
}

#-------------------------------------------------------------------------------
sub print_log
{
	my($log_type, $log_message) = @_;

	my $timestamp = `date +"%d-%b-%Y %T"`;
	chomp($timestamp);  # Trimming New line at the end of string

	my $log_filename = $global_cfg{'log_file'};
	my $output_filename = $global_cfg{"output_file"};

	if ($log_type eq $LOG)
	{
		# Writing to log_file
		open(FH, ">>$log_filename");
		print FH $timestamp . " : " . $log_message . "\n";
		close(FH);
	}elsif ($log_type eq $OUT)
	{
		# Writing to output_file
		open(FH, ">>$output_filename");
		print FH $timestamp . " : " . $log_message . "\n";
		close(FH);
	}elsif ($log_type eq $ALL)
	{
		my $error = "";
		if(substr($log_message, length($log_message) - 1, 1) eq "\n")
		{
			$error = "Error - " . $log_message;
			$log_message = "FAIL\n";
		}else
		{
			if($log_message eq "PASS" || $log_message eq "FAIL")
			{
				$log_message = $log_message . "\n";
			}elsif($log_message eq $SUCCESS)
			{
				$log_message = "PASS\n";
			}else
			{
				$log_message = $log_message . " ............. ";
			}
		}
		
		#Writing to screen
		if($global_cfg{'print_output_in_screen'} eq $YES)
		{
			print $log_message;
		}

		# Writing to log_file
		open(FH, ">>$log_filename");
		print FH $timestamp . " : " . $log_message . "" . $error;
		close(FH);
		
		# Writing to output_file
		open(FH, ">>$output_filename");
		print FH $log_message . "" . $error;
		close(FH);
	}else # "ANY"
	{
		# Writing to log_file
		open(FH, ">>$log_filename");
		print FH $timestamp . " : " . $log_message . "\n";
		close(FH);

		# Writing to output_file
		open(FH, ">>$output_filename");
		print FH $timestamp . " : " . $log_message . "\n";
		close(FH);
	}
}
#-------------------------------------------------------------------------------
sub get_class_count
{
	my($session) = @_;
	my $cmd = "app\nshow class all\n";
	print_log($LOG, "CMD : $cmd");
	# Sending command
	my $out = $session->send("$cmd");

	# Expecting the starting header
	unless($session->expect($timeout, "-re", "show class all\n-+\n\|Name.*\n-.*"))
	{
		return "Not able to get the show class all output\n";
	}

	# Expecting the ending header
	unless($session->expect($timeout, "-re", "^[-]+"))
	{
		return "Not able to get end of show class all output\n";
	}

	# Copying the classes into an array
	my @output = split("\n",$session->before());
	
	# Getting the class count
	my $class_count = $#output;
	print_log($LOG, "Checking the class count - Found $class_count classes");

	return "$class_count";
}
#-------------------------------------------------------------------------------
sub get_policy_count
{
	my($session) = @_;
	my $cmd = "policy\nshow policy all\n";
	print_log($LOG, "CMD : $cmd");
	# Sending command
	my $out = $session->send("$cmd");

	# Expecting the starting header
	unless($session->expect($timeout, "-re", "show policy all\n-+\n\|Name.*\n-.*"))
	{
		return "Not able to get the show policy all output\n";
	}

	# Expecting the ending header
	unless($session->expect($timeout, "-re", "^[-]+"))
	{
		return "Not able to get end of show policy all output\n";
	}

	# Copying the policies into an array
	my @output = split("\n",$session->before());

	# Getting the class count
	my $policy_count = $#output;
	print_log($LOG, "Checking the policy count - Found $policy_count policies");

	return "$policy_count";
}
#-------------------------------------------------------------------------------
sub get_filter_count
{
	my($session) = @_;
	my $cmd = "policy\nshow filter all\n";
	print_log($LOG, "CMD : $cmd");
	# Sending command
	my $out = $session->send("$cmd");

	# Expecting the starting header
	unless($session->expect($timeout, "-re", "show filter all\n-+\n\|Name.*\n-.*"))
	{
		return "Not able to get the show filter all output.\n";
	}

	# Expecting the ending header
	unless($session->expect($timeout, "-re", "^[-]+"))
	{
		return "Not able to get end of show filter all output.\n";
	}

	# Copying the filters into an array
	my @output = split("\n",$session->before());

	# Getting the class count
	my $filter_count = $#output;
	print_log($LOG, "Checking the filter count - Found $filter_count filters");

	return "$filter_count";
}


#-------------------------------------------------------------------------------
=create_pattern
$patternformat:
	l7pattern: 
	url:       
	port:      
	srcport:   
	dstport:   
	srcip:     
	srciplist: 
	dstip:
	dstiplist:
	ipproto:   
	vlanid:    
	mpls:      
	dscp:      
	user:      
	group:     
=cut
sub create_pattern
{
	my($session, $pattname, $patternformat) = @_;

	my $cmd = "app\nnew pattern $pattname $patternformat";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd\n";

	unless ($session->expect($timeout, "New pattern $pattname created successfully"))
	{
		return "Not able to create pattern $pattname ($patternformat)\n";
	}

	return $SUCCESS;
}

#-------------------------------------------------------------------------------
sub create_class
{
	my($session, $classname, $linkname, $pattname, $refclassname, $pattern_type) = @_;
	
	if ($refclassname)
	{
 		$refclassname = "refclass: $refclassname";
	}
	
	if($pattern_type eq "list")
	{
		$pattname = "list: $pattname";
	}
	else
	{
		$pattname = "pattern: $pattname";
	}
	
	my $cmd = "app\nnew class $classname $linkname any Custom $pattname $refclassname\n";
	trim($cmd);
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	my $match = "New class $classname created successfully. Please use sync command to activate new class";
	unless ($session->expect($timeout, "$match"))
	{
		my $out = $session->before();
		return "Not able to create class $classname ($linkname) with pattern ( $pattname $refclassname)\n$out";
	}

	return $SUCCESS;
}

#-------------------------------------------------------------------------------
sub create_policy
{
	my($session, $policyname, $policytype) = @_;

	my $cmd = "policy\nnew policy $policyname $policytype";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd\n";

	unless ($session->expect($timeout, "New policy $policyname created successfully"))
	{
		return "Not able to create policy $policyname ($policytype)\n";
	}

	return $SUCCESS;
}

#-------------------------------------------------------------------------------
sub set_wan_speed
{
	my($session, $linkname, $inbound_speed, $outbound_speed) = @_;

	my $cmd = "system\nconfig wan speed $linkname inbound: $inbound_speed outbound: $outbound_speed";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd\n";

	my $exp_output = "Configured WAN link speed for $linkname to Inbound : $inbound_speed" . "kbps, Outbound : $outbound_speed" . "kbps successfully";

	unless ($session->expect($timeout, $exp_output))
	{
		my $out = $session->before();
		my $error = "Not able to set wan speed for $linkname, IN:$inbound_speed kbps, OUT: $outbound_speed kbps\n$out";
		return $error;
	}

	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub set_class_limit
{
	my($session, $limit) = @_;

	my $cmd = "global\nset limit class $limit";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd\n";

	unless ($session->expect($timeout, "Configured limit on number of classes to $limit successfully"))
	{
		my $out = $session->before();
		my $error = "Not able to set the class limit\n$out";
		return $error;
	}

	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub set_flow_limit
{
	my($session, $limit, $threshold, $limitaction) = @_;

	if ($threshold)
	{
		$threshold = "threshold: $threshold";
	}

	if ($limitaction)
	{
		$limitaction = "limitaction: $limitaction";
	}

	my $cmd = "global\nset limit flow $limit $threshold $limitaction";
	trim($cmd);
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd\n";

	unless ($session->expect($timeout, "Configured flow limit to $limit successfully"))
	{
		my $out = $session->before();
		my $error = "Not able to set the flow limit\n$out";
		return $error;
	}

	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub set_pattern_limit
{
	my($session, $limit) = @_;

	my $cmd = "global\nset limit pattern $limit";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd\n";

	unless ($session->expect($timeout, "Configured limit on number of pattern to $limit successfully"))
	{
		my $out = $session->before();
		my $error = "Not able to set the pattern limit\n$out";
		return $error;
	}

	return $SUCCESS;
}
#-------------------------------------------------------------------------------
sub set_policy_limit
{
	my($session, $limit) = @_;
	
	my $cmd = "global\nset limit policy $limit";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd\n";

	unless ($session->expect($timeout, "Configured limit on number of policies to $limit successfully"))
	{
		my $out = $session->before();
		my $error = "Not able to set the policy limit\n$out";
		return $error;
	}

	return $SUCCESS;
}

#-------------------------------------------------------------------------------
sub upgrade_to_latest_build
{
	my ($session_ref) = @_;
	my $session = $$session_ref;
	
	my $build_ftp_url;
	my $build_http_url;
	
	if($cfg{"appliance_type"} eq "cavium")
	{
		$build_ftp_url = $global_cfg{"latest_build_ftp_url"};
		$build_http_url = $global_cfg{"latest_build_url"};
	}elsif($cfg{"appliance_type"} eq "intel")
	{
		$build_ftp_url = $global_cfg{"intel_latest_build_ftp_url"};
		$build_http_url = $global_cfg{"intel_latest_build_url"};
	}
	
	# From the HTTP page, we will get the name of the available latest version
	`rm latest_build* > /dev/null 2>/dev/null`;
	`wget -q --user=guest --password=testpass $build_http_url --no-check-certificate --output-document latest_build.html`;
	
	my $out = `cat latest_build.html | grep eagle-x86`;
	if($cfg{"appliance_type"} eq "cavium")
	{
		$out = `cat latest_build.html | grep eagle-`;
	}
	
	my ($build_name) = $out =~ /(?<=>)eagle-.*.rpm/g;
	
	my $latest_build_url = $build_ftp_url."".$build_name;
	my $cmd = "system\nimg download $latest_build_url\n";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd\n";
	
	unless($session->expect(10,"Image downloaded successfully from $latest_build_url"))
	{
		return "Failed to Download the Image from the FTP server\n";
	}
	$cmd = "img activate\n";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	if($session->expect($shorttimeout,"Are you sure you want to proceed? Yes/No"))
	{
		$cmd = "yes\n";
		print $session "$cmd";
	}
	
	if($session->expect(50,"activated successfully"))
	{
		print_log($LOG, "New image $build_name Activated successfully");
		if($session->expect(50,"Connection to $cfg{\"appliance_ip\"} closed"))
		{
			sleep(10);
			execute(wait_till_up($cfg{"appliance_ip"}, 100));
			$session = execute_ssh(login($cfg{"appliance_ip"}, $cfg{"appliance_username"}, $cfg{"appliance_password"}));
		}
		$cmd = "system\n";
		print $session "$cmd\n";
		$$session_ref = $session;
		if($session->expect($shorttimeout,"System >"))
		{
			return $SUCCESS;
		}
	}elsif($session->expect(50,"\'img download\' failed, package update error"))
	{
		return $session->after().$FAIL."\n";
	}
	return $FAIL;
}

#-------------------------------------------------------------------------------
sub install_latest_build
{	
	my $session = execute_ssh(login($cfg{"appliance_ip"}, $cfg{"appliance_root_username"}, $cfg{"appliance_root_password"}));
	
	my $build_http_url;
	
	if($cfg{"appliance_type"} eq "cavium")
	{
		$build_http_url = $global_cfg{"latest_build_url"};
	}elsif($cfg{"appliance_type"} eq "intel")
	{
		$build_http_url = $global_cfg{"intel_latest_build_url"};
	}
	
	# From the HTTP page, we will get the available latest version
	
	`rm latest_build*; > /dev/null 2>&1`;
	`wget -q --user=guest --password=testpass $build_http_url --no-check-certificate --output-document latest_build.html`;
	
	my $out = `cat latest_build.html | grep eagle-x86`;
	if($cfg{"appliance_type"} eq "cavium")
	{
		$out = `cat latest_build.html | grep eagle-`;
	}
	
	my ($build_name) = $out =~ /(?<=>)eagle-.*.rpm/g;
	
	my $latest_build_url = $build_http_url."".$build_name;
	
	my $cmd = "wget --user=guest --password=testpass $latest_build_url --no-check-certificate --output-document /tmp/$build_name";
	print $session "$cmd\n";
	
	unless($session->expect($timeout,"Saving to"))
	{
		return "Failed to download the .rpm package\n";
	}
	
	my $match = "/tmp/$build_name' saved";
	
	unless($session->expect(100, $match))
	{
		return "Failed to download the .rpm package a\n";
	}

	# Checking and Uninstalling the rpm package, if there is already installed
	if($cfg{"appliance_type"} eq "intel")
	{
		$cmd = "rpm -qa | grep eagle && rpm -e eagle-x86";
		print $session "$cmd\n";
	}elsif($cfg{"appliance_type"} eq "cavium")
	{
		$cmd = "rpm -qa | grep eagle && rpm -e eagle";
		print $session "$cmd\n";
	}
	
	unless($session->expect(60, "Completed uninstalling"))
	{
		return "Build Uninstall failed\n";
	}
	
	if($cfg{"appliance_type"} eq "cavium")
	{
		$cmd = "reboot";
		print $session "$cmd\n";
		if($session->expect(30,"Connection to $cfg{\"appliance_ip\"} closed"))
		{
			sleep(10);
			execute(wait_till_up($cfg{"appliance_ip"}, 100));
			$session = execute_ssh(login($cfg{"appliance_ip"}, $cfg{"appliance_root_username"}, $cfg{"appliance_root_password"}));
		}
	}
	$cmd = "./install_rpm.pl /tmp/$build_name";
	print $session "$cmd\n";
	
	$match = "Installing /tmp/$build_name success";
	
	unless($session->expect(60, $match))
	{
		return "Build $build_name install failed\n";
	}
	
	print $session "rpm -qa | grep eagle\n";
		
	return $SUCCESS;
}

#-------------------------------------------------------------------------------
sub start_iperf_server
{
	my ($session, $pid_ref, $options) = @_;
	
	my $cmd = "iperf -s ";
	
	if(defined $options)
	{
		$cmd .= $options;
	}
	$cmd = trim($cmd);
	print $session "$cmd&\n";
	my $match = $options."&";
	if($session->expect(2, $match))
	{
		my @out=split("\n", $session->after());
		$$pid_ref = substr(trim(@out[1]),4);
	}

	$match = "Server listening on";
	unless($session->expect(1, $match))
	{
		return "Failed to start iperf server.\n";
	}
	print_log($LOG, "Iperf Server started successfully - $cmd");
	return $SUCCESS;
}

#-------------------------------------------------------------------------------
sub start_iperf_client
{
	my ($session, $pid_ref, $options) = @_;
	
	my $cmd = "iperf";
	
	if(defined $options)
	{
		$cmd .= $options;
	}
	unless(defined $session)
	{
		return "Connection lost.\n";
	}
	print $session "$cmd&\n";
	my $match = "\$ $cmd&";
	if($session->expect(1, $match))
	{
		my @out=split("\n", $session->after());
		$$pid_ref = substr(trim(@out[1]),4);
	}
	
	$match = "Client connecting to ";
	unless($session->expect(15, $match))
	{
		return "Failed to start iperf Client. - $cmd\n";
	}
	print_log($LOG, "iperf Client started successfully. - $cmd");
	return $SUCCESS;
}
#-------------------------------------------------------------------------------
sub get_link_stats
{
	my($session, $stats_ref, $link, $window, $start, $end) = @_;
	my $error;
	
	#check what are all the parameters sent
	unless(defined $session)
	{
		return "Session is Mandatory param\n";
	}
	
	unless(defined $stats_ref)
	{
		return "Hash reference is Mandatory param\n";
	}
		
	unless(defined $link)
	{
		$link = $LINK0;
	}
	
	if(defined $window)
	{
		$window = "window: $window ";
	}
	else
	{
		$window = "";
	}
	
	if(defined $start)
	{
		$start = "starttime: $start ";
	}
	else
	{
		$start = "";
	}
	
	if(defined $end)
	{
		$end = "endtime: $end ";
	}
	else
	{
		$end = "";
	}
	my $cmd = "global\n show stats interface $link any " . $window . $start . $end . "\n";
	print_log($LOG, "Link stats CMD : $cmd");
	print $session "$cmd";
	
	# Expecting the starting header
	unless($session->expect($shorttimeout, "-re", "show stats interface $link any\n-+\n\|Name.*\n[-]+"))
	{
		return "Not able to get the \"show stats interface $link any\" output.\n";
	}

	# Expecting the ending header
	unless($session->expect($shorttimeout, "-re", "^[-]+"))
	{
		return "Not able to get end of \"show stats interface $link any\" output.\n";
	}
	
	unless($session->before())
	{
		return "Unexpected Error.\n";
	}
	my @stats_output = split("\n",$session->before());
	
	unless(@stats_output[1] || @stats_output[2])
	{
		return "There is no link stats available for $link.\n"
	}
	
	my @int_line = split($delim, @stats_output[1]);
	my @ext_line = split($delim, @stats_output[2]);
	
	$stats_ref->{'ls_link'} = $link;
	
	$stats_ref->{'ls_int_flow_count'} = trim(@int_line[2]);
	$stats_ref->{'ls_int_rx_bytes'} = trim(@int_line[3]);
	$stats_ref->{'ls_int_tx_bytes'} = trim(@int_line[4]);
	$stats_ref->{'ls_int_rx_kbps'} = trim(@int_line[5]);
	$stats_ref->{'ls_int_tx_kbps'} = trim(@int_line[6]);
	
	$stats_ref->{'ls_ext_flow_count'} = trim(@ext_line[2]);
	$stats_ref->{'ls_ext_rx_bytes'} = trim(@ext_line[3]);
	$stats_ref->{'ls_ext_tx_bytes'} = trim(@ext_line[4]);
	$stats_ref->{'ls_ext_rx_kbps'} = trim(@ext_line[5]);
	$stats_ref->{'ls_ext_tx_kbps'} = trim(@ext_line[6]);
	
	return $SUCCESS;
}

#-------------------------------------------------------------------------------
sub get_flow_summary
{
	
	my($session, $summary_ref, $window) = @_;
	my $error;
	
	#check what are all the parameters sent
	unless(defined $session)
	{
		return "Session is Mandatory param\n";
	}
	
	unless(defined $summary_ref)
	{
		return "Hash reference is Mandatory param\n";
	}
	
	unless(defined $window)
	{
		$window = "last_min";
	}
	my $cmd = "app\nshow flow_summary summarise_by: app top: 1 window: $window\n";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	# Expecting the starting header
	unless($session->expect($shorttimeout, "-re", "show flow_summary summarise_by: app top: 1 window: $window\n-+\n\|Application.*\n-.*"))
	{
		return "Not able to get the \"show flow_summary summarise_by: app top: 1 window: $window\" output.\n";
	}

	# Expecting the ending header
	unless($session->expect($shorttimeout, "-re", "^[-]+"))
	{
		return "Not able to get end of \"show flow_summary summarise_by: app top: 1 window: $window\" output.\n";
	}
	
	unless($session->before())
	{
		return "Unexpected Error.\n";
	}
	
	my @summary_output = split("\n",$session->before());
	unless(@summary_output[1])
	{
		return "There is no flow summary available for $window.\n"
	}
	my @app_1_line = split($delim, @summary_output[1]);
	
	$summary_ref->{'fs_app_name'} = trim(@app_1_line[1]);
	$summary_ref->{'fs_flow_count'} = trim(@app_1_line[2]);
	$summary_ref->{'fs_bytes'} = trim(substr(@app_1_line[3], 0, length(@app_1_line[3]) - 1));
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------
sub rollback_image
{
	my ($session_ref) = @_;
	my $session = $$session_ref;
	my $cmd = "system\nimg rollback force\n";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	unless($session->expect($shorttimeout,"The appliance image will be updated to the previous version"))
	{
		return "Failed to rollback to the previous version.\n";
	}
	
	if($session->expect($shorttimeout,"Are you sure you want to proceed? Yes/No"))
	{
		$cmd = "yes";
		print $session "$cmd\n";
	}
	if($session->expect(50,"Image successfully rolled back to"))
	{
		if($session->expect(30,"Connection to $cfg{\"appliance_ip\"} closed"))
		{
			sleep(10);
			execute(wait_till_up($cfg{"appliance_ip"}, 100));
			$session = execute_ssh(login($cfg{"appliance_ip"}, $cfg{"appliance_username"}, $cfg{"appliance_password"}));
		}
		$cmd = "system\n";
		print $session "$cmd\n";
		$$session_ref = $session;
		if($session->expect($shorttimeout,"System >"))
		{
			return $SUCCESS;
		}
	}
	return $FAIL;
}

#-------------------------------------------------------------------------------
sub get_software_version
{
	my($session, $version_ref) = @_;
	my $error;
	
	my $cmd = "system\nshow img";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd\n";
	
	# Expecting the starting header
	unless($session->expect($timeout, "-re", "show img.*\nDisplaying image information\n-+\n\|Parameter.*Value.*\n-.*"))
	{
		return "Not able to get the $cmd output.\n";
	}

	# Expecting the ending header
	unless($session->expect($shorttimeout, "-re", "^[-]+"))
	{
		return "Not able to get end of $cmd output.\n";
	}
	
	unless($session->before())
	{
		return "Unable to get Output\n";
	}
	my @stats_output = split("\n",$session->before());

	unless(@stats_output[1] || @stats_output[2])
	{
		return "There is no software version available.\n"
	}
	
	my @current_version_line = split($delim, @stats_output[1]);
	my @insatallation_time_line = split($delim, @stats_output[2]);
	my @build_time_line = split($delim, @stats_output[3]);
	my @downloaded_version_line = split($delim, @stats_output[4]);
	my @previous_version_line = split($delim, @stats_output[5]);
	my @factory_version_line = split($delim, @stats_output[5]);
	
	$version_ref->{'ver_current'} = trim(@current_version_line[2]);
	$version_ref->{'ver_installation_time'} = trim(@insatallation_time_line[2]);
	$version_ref->{'ver_build_time'} = trim(@build_time_line[2]);
	$version_ref->{'ver_downloaded'} = trim(@downloaded_version_line[2]);
	$version_ref->{'ver_previous'} = trim(@previous_version_line[2]);
	$version_ref->{'ver_factory'} = trim(@factory_version_line[2]);

	return $SUCCESS;
}

#-------------------------------------------------------------------------------
sub assign_policy
{
	my ($session, $policy_name, $class_name) = @_;
	# assigning policy to the class
	my $cmd = "policy\nassign policy $policy_name $class_name\n";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	my $match = "Assigned policy $policy_name to $class_name successfully";
	unless($session->expect(1, $match))
	{
		return "Failed to assign policy $policy_name to $class_name.\n";
	}
	return $SUCCESS;
}

#-------------------------------------------------------------------------------
sub change_policy
{
	my ($session, $policy_name, $options) = @_;
	my $cmd = "policy\nset policy $policy_name $options\n";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	my $match = "Updated policy $policy_name successfully";
	unless($session->expect(1, $match))
	{
		return "Failed to change policy $policy_name.\n";
	}
	return $SUCCESS;
}

#-------------------------------------------------------------------------------
sub set_pipe
{
	my ($session, $pipe_min, $pipe_max, $class_name, $direction) = @_;
	
	if(not defined $direction)
	{
		$direction = " ";
	}
	
	my $cmd = "policy\nnew pipe" . $direction . "min $pipe_min burstmax: $pipe_max $class_name\n";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	if(" " eq $direction)
	{
		$direction = "any";
	}
	
	$direction = trim($direction);
	
	my $match = "Added new pipe min:" . $pipe_min . "kbps, max:" . $pipe_max . "kbps for class $class_name ($direction)successfully";
	unless($session->expect($timeout, $match))
	{
		return "Failed to assign $direction pipe min " . $pipe_min . "kbps, max:" . $pipe_max . "kbps for $class_name. Direction $direction.\n";
	}
	return $SUCCESS;
}

#-------------------------------------------------------------------------------

sub set_shaping_on
{
	my ($session) = @_;
	# Check shaping is on, unless turn on it
	my $cmd = "policy\nset shaping on\n";
	print_log($LOG, "CMD : $cmd");
	unless(is_shaping_on($session) eq $SUCCESS)
	{
		print $session "$cmd";
		unless($session->expect($timeout, "Shaping turned on successfully"))
		{
			return "Failed to turn on Shaping.\n";
		}
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub set_shaping_off
{
	my ($session) = @_;
	# Check shaping is off, unless turn off it
	my $cmd = "policy\nset shaping off\n";
	print_log($LOG, "CMD : $cmd");
	unless(is_shaping_on($session) ne $SUCCESS)
	{
		print $session "$cmd";
		unless($session->expect($timeout, "Shaping turned off successfully"))
		{
			return "Failed to turn off Shaping.\n";
		}
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub delete_classes
{
	my ($session, @classes) = @_;
	my $cmd = "app\n";
	print $session "$cmd";
	
	foreach(@classes)
	{
		$cmd = "delete class $_\n";
		print_log($LOG, "CMD : $cmd");
		print $session "$cmd";
		my $match = "Deleted class $_ successfully";
		unless($session->expect(20, $match))
		{
			return "Failed to delete class $_.\n";
		}
	}
	return $SUCCESS;
}

#-------------------------------------------------------------------------------
sub delete_policies
{
	my ($session, @policies) = @_;
	my $cmd = "policy\n";
	print $session "$cmd";
	foreach(@policies)
	{
		$cmd = "delete policy $_\n";
		print_log($LOG, "CMD : $cmd");
		print $session "$cmd";
		my $match = "Deleted policy $_ successfully";
		unless($session->expect($shorttimeout, $match))
		{
			return "Failed to delete policy $_.\n";
		}
	}
	return $SUCCESS;
}

#-------------------------------------------------------------------------------

sub get_date
{
	my ($session, $str_ref, $options) = @_;
	my $cmd = "datestr=\$(date " . $options . ");echo \$datestr\n";
	print $session "$cmd";
	my $match = "echo \$datestr";
	unless($session->expect($shorttimeout, $match))
	{
		return "Error while getting date 1.\n";
	}
	$match = "[root";
	unless($session->expect($shorttimeout, $match))
	{
		return "Error while getting date 2.\n";
	}
	$$str_ref = $session->before();
	chomp($$str_ref);
	trim($$str_ref);
	$$str_ref = substr($$str_ref, 2, 8);
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub collect_dpconsole_output
{
	my ($session, @commands) = @_;
	my $cmd = "/opt/eagle/intel/bin/eagle_console\n";
	my $match = "Successfuly opened DP console";
	print $session "$cmd";
	unless($session->expect($shorttimeout, $match))
	{
		return "Error while starting eagle_console";
	}
	sleep(1);
	foreach(@commands)
	{
		$cmd = "$_\n";
		print $session "$cmd";
		my $match = "Command sent to DP";
		unless($session->expect($timeout, $match))
		{
			return "Failed to get output of $_.\n";
		}
		$match = "DATA-PLANE>";
		unless($session->expect($timeout, $match))
		{
			return "Failed to get output of $_.\n";
		}
		sleep(1); # Sleep for 1 second
		$cmd = "\n";
		print $session "$cmd";
		unless($session->expect($timeout, $match))
		{
			return "Failed to get output of $_.\n";
		}
	}
	$cmd = "\003\n"; # Sending (ctrl + c) to exit from the eagle_console
	print $session "$cmd";
	$cmd = "date\n";
	print $session "$cmd";
	$match = "IST";
	unless($session->expect($shorttimeout, $match))
	{
		return "Failed to exit from DP console.\n";
	}
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub start_iperf_clients
{
	my ($session, $pid_ref, $server_ip, $no_of_flows, $flow_duration, $total_duration, $flow_rate, $option) = @_;
	my $seconds_to_run;
	unless(defined $server_ip)
	{
		return "Please provide server ip.\n";
	}
	unless(defined $no_of_flows)
	{
		$no_of_flows = 1;
	}
	unless(defined $flow_duration)
	{
		$flow_duration = 120;
		$seconds_to_run = 1;
	}
	unless(defined $total_duration)
	{
		$total_duration = 120;
	}
	unless(defined $flow_rate)
	{
		$flow_rate = 15;
	}
	
	if($flow_rate < 15)
	{
		$flow_rate = 15;
	}
	if($flow_duration < 120)
	{
		$seconds_to_run = 120;
	}
	my $options;
	#for(my $i = 0; $i < $seconds_to_run ; $i++ )
	#{	
		if( $no_of_flows <= 350 && $no_of_flows > 0)
		{
			$options = " -c $server_ip -t $flow_duration -P $no_of_flows ".$option;
			execute(start_iperf_client($session, $pid_ref, $options));
		}elsif($no_of_flows > 0)
		{
			my $thread_count = $no_of_flows;
			
			for (my $j=0; $j <= $no_of_flows; $j+=350) 
			{	
				if($thread_count >= 350 && ($thread_count / 350) > 0)
				{
					$options = " -c $server_ip -t $flow_duration -P 350 ".$option;
				}elsif($thread_count <= 350)
				{
					$options = " -c $server_ip -t $flow_duration -P ".$thread_count." ".$option;
				}
				execute(start_iperf_client($session, $pid_ref, $options));
				$thread_count -= 350;
			}
		}else
		{
			return "Cannot start iperf Clients\n";
		}
	#	sleep(1);
	#}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub scp_file
{
	my ($session, $source, $destination, $pass) = @_;
	my $cmd = "scp $source $destination";
	print $session "$cmd\n";
	
	if($session->expect($timeout, "yes\/no"))
	{
		print $session "yes\n";
	}
=unless($session->expect(10,"password:"))
	{
		return "Timed out when waiting for password : SCP.\n";
	}

	print $session "$pass\n";
	my $match = "$cfg{'scp_file_location'}";
	unless($session->expect(1,$match))
	{
		return $FAIL;
	}
=cut
	return $SUCCESS;
}
#-------------------------------------------------------------------------------
sub app_sync
{
	my ($session) = @_;
	my $cmd = "app\nsync\n";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd\n";
	unless($session->expect(30, "Activated new patterns and classes successfully"))
	{
		return "Failed to sync.\n";
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub ping_test_from_server
{
	my ($ser_session) = @_;
	return ping($ser_session, $cfg{"client_loc_eth_ip"}, 1);
}
#-------------------------------------------------------------------------------

sub ping_test_from_client
{
	my ($cli_session) = @_;
	return ping($cli_session, $cfg{"server_loc_eth_ip"}, 1);
}
#-------------------------------------------------------------------------------

sub ping
{
	my ($session, $ipaddress, $remote) = @_;
	my $cmd = "ping -c 10 " . $ipaddress;
	if(not defined $remote)
	{
		print $session `$cmd\n`;
	}else
	{
		print $session "$cmd\n";
	}
	my $match = "ping statistics";
	unless($session->expect(15, $match))
	{
		return "Ping command failed.\n";
	}
	$match = "10 packets transmitted, 10 received, 0% packet loss";
	unless($session->expect(1, $match))
	{
		return "Ping connection to $ipaddress failed.\n";
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub unassign_policy
{
	my ($session, $policy_name, $options) = @_;
	my $cmd = "policy\nunassign policy $policy_name $options\n";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	my $match = "Unassigned policy $policy_name to $options successfully";
	unless($session->expect(1, $match))
	{
		return "Failed to unassign policy $policy_name to $options.\n";
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub killall
{
	my ($session, $process_name) = @_;
	for(my $i = 0 ; $i < 5 ; $i++)
	{
		print $session "killall -9 $process_name\n";
		if($session->expect(1, "$process_name: no process found"))
		{
			$i = 5;
		}
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub parse_input_from_file
{
	my ($input_file, $alltest) = @_;
	
	my $file = "$input_file";
	open my $in, $file or die "Could not open $file: $!";

	while(my $line = <$in>)  
	{
		my @str = split($delim, $line);
		my %test = ();
		
		print_log($LOG, "Input Line : " .join(", ", @str));
		
		$test{'test_id'} = @str[0];
		$test{'wan_speed'} = @str[1];
		$test{'test_duration'} = @str[2];
		
		my @str1 = @str[3..$#str];
		my $loop_count = ($#str1 / 7);
		my $i = 0;
		for(my $j = 0 ; $j < $loop_count; $j++)
		{
			my @class = (@str1[0+$i], @str1[1+$i], @str1[2+$i], @str1[3+$i], @str1[4+$i], @str1[5+$i], int(@str1[6+$i]));
			$i += 7;
			$test{"class_$j"} = [@class];
		}
		push @{$alltest} , \%test;
	}

	close $in;
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub create_adagent
{
	my ($session, $adagent) = @_;

	my $cmd = "system\nshow ADAgents\n";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	my $match = "$adagent";
	if($session->expect($timeout, "$match"))
	{
		delete_adagent($session, $adagent);
	}
	
	$cmd = "config ADIntegration status: on\n";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	$match = "AD Sync configured successfully.";
	$session->expect($timeout, "$match");
	
	$cmd = "add ADAgent $adagent\n";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	$match = "AD agent $adagent added successfully.";
	unless($session->expect($timeout, "$match"))
	{
		return "Unable to add ADAgent $adagent to the appliance.\n";
	}
	
	$cmd = "config ADIntegration status: off\nconfig ADIntegration status: on\n";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	$match = "AD Sync configured successfully.";
	$session->expect($timeout, "$match");
	unless($session->expect($timeout, "$match"))
	{
		return "Unable to turn on ADIntegration.\n";
	}
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub delete_adagent
{
	my ($session, $adagent) = @_;
	my $cmd = "system\ndelete ADAgent $adagent\n";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	my $match = "Do you really wish to delete AD agent now? Yes/No";
	unless($session->expect($timeout, "$match"))
	{
		return "Unable to delete ADAgent $adagent from the appliance.\n";
	}
	$cmd = "yes\n";
	print $session "$cmd";
	print_log($LOG, "CMD : $cmd");
	$match = "AD agent $adagent deleted successfully.";
	unless($session->expect($timeout, "$match"))
	{
		return "Unable to delete ADAgent $adagent from the appliance.\n";
	}
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub collect_class_stats
{
	my ($session, @classes) = @_;
	my %stats = ();
	my %if_stats = ();
	

	# Waiting for collecting stats
	print_log($ANY, "Started traffic for 100 secs....");
	sleep(100);

	execute(get_link_stats($session, \%if_stats, $LINK0, "last_min"));
	

	my $report =     "\n------------- Test Output Summary ------------\n";
	$report = $report . "Classname\t|RateIN\t|RateOUT |Flows\n";
	$report = $report . "----------------------------------------------\n";
	
	foreach(@classes)
	{
		%stats = ();
		execute(get_class_stats($session, \%stats, $_, "last_min", $LINK0));
		$report = $report . $_ . "|$stats{\"cs_in_tx_kbps\"}\t|$stats{\"cs_out_tx_kbps\"}\t |" . $stats{"cs_out_flow_count"} + $stats{"cs_in_flow_count"} . "\n";
	}
	$report = $report . "----------------------------------------------\n";
	$report = $report . "Interface\t|RateIN\t|RateOUT |Flows\n";
	$report = $report . $if_stats{'ls_link'}. "|$if_stats{'ls_int_tx_kbps'}\t|$if_stats{'ls_ext_tx_kbps'}\t |" . $if_stats{'ls_ext_flow_count'} + $if_stats{'ls_int_flow_count'} . "\n";
	$report = $report . "----------------------------------------------\n\n\n";

	print_log($ANY, $report);
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub send_mail
{
	my ($sub, $content, $attach_logs) = @_;
	
	if ($global_cfg{"send_mail"} eq $NO)
	{
		return $SUCCESS;
	}
	print_log($LOG, "Mail\nFrom : $global_cfg{'from_mail_id'}\nTo : $global_cfg{'to_mail_id'}. \nSub : $sub \nMessage : $content");
	my $mail = MIME::Lite->new(
			From    => $global_cfg{"from_mail_id"},
			To      => $global_cfg{"to_mail_id"},
			Subject => $sub,
			Type    => 'multipart/related'
		);
		
	$mail->attach(
		Type     =>'TEXT',
		Data     =>$content
		);
	if(defined $attach_logs)
	{
		$mail->attach(
			Type     => 'TEXT',
			Path     => $global_cfg{"output_file"},
			Filename => 'Eagle Sanity Test Output file.txt',
			Disposition => 'attachment'
			);
			
		$mail->attach(
			Type     => 'TEXT',
			Path     => $global_cfg{'log_file'},
			Filename => 'Eagle Sanity Test logfile.txt',
			Disposition => 'attachment'
			);
	}
	$mail->send;
	print_log($LOG, "Mail sent");
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub get_local_ip_address {
    my $socket = IO::Socket::INET->new(
        Proto       => 'udp',
        PeerAddr    => '8.8.8.8', # a.root-servers.net
        PeerPort    => '53', # DNS
    );
   return $socket->sockhost;
}
#-------------------------------------------------------------------------------

sub add_user
{
	my ($session, $username, $usertype, $passwd) = @_;
	my $cmd = "system\nadd user $usertype $username $passwd\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	my $match = "User $username added successfully.";
	
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to create the user $username.\n";
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub change_password
{
	my ($session, $username, $passwd) = @_;
	my $cmd = "system\nconfig password username: $username passwd: $passwd\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	my $match = "Password updated for $username successfully";
	
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to change password for the user $username.\n";
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub delete_user
{
	my ($session, $username) = @_;
	my $cmd = "system\ndelete user $username\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	my $match = "User $username deleted successfully.";
	
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to delete the user $username.\n";
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

=trim
	Trim the trailer white space from the given string
=cut
sub trim 
{
    (my $s = $_[0]) =~ s/^\s+|\s+$//g;
    return $s;        
}
#-------------------------------------------------------------------------------

1;
