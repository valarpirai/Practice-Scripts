
Test Simulation using iperf

List of required applications on end-hosts
	*iperf

Script Environment requirements
	* perl(5.10.1), Expect - for running the perl script with expect.
		* yum install -y cpan
		* perl -MCPAN -e "CPAN::Shell->force(qw(install Expect));"
	
Configuration to be done on end-host
	* ip configuration for the interfaces connected to DUT
	* check server side is connected to LAN Link on DUT
	* check client side is connected to WAN Link on DUT
	  [data is pushed from client to server]
Pre-Configuration script [config to be done on DUT]
	* run the following script to create the custom class
	  perl iperf_class.pl -a create
	NOTE : this script needs to be run only once for multiple test runs
Configuration to be done on the Test Server [from where the script is run]
	* sys_config/eagle.cfg - Contains the appliance, client, server configurations
	  update the IP Addresses based on DUT, server, client interface ip
	  update user credentials for respective systems

	Config file has a list of pre-defined tests which can be run from the script
	the DUT, test hosts etc are controlled/configured based on respective tests,
	* to control list of tests to be run select yes/no against the test case

	for eg, to run 3SLA_2BURST test case which assigns SLA for 3 applications and
	runs 5 application traffic to demo that SLA traffic is guaranteed, update the 
	following line in the config file,

	RUN_3SLA_2BURST=>"yes",

List of applications simulated
	* HTTP
	* LDAP
	* SSL
	* SMB
	* IPERF [test utility application]

How to Run?
	perl iperf_apps.pl -a eagle -w <WAN Speed in Mbps> -t <test duration in secs>

Check Test run
	Following log files are created in directory from where the test is run,

	tail -f test_logs_<timestamp> #test start time is appended to the test log filename
	Results are also captured in this file

	detailed test execution log [includes cli commands on DUT]
	tail -f test_output_<timestamp>

