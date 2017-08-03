#!/usr/bin/perl

use perl_modules::common;
use POSIX;

# Need to run this perl file with sudo permission to run tcpreplay command

execute(load_config("228"));

$session = execute_ssh(login("192.168.1.228", "root", "testpass"));


my %pcap_cfg = ();
my %app_cfg = ();
my $cfg_loc = "/home/valar/pcaps/conf/";
my $pcap_loc = "/home/valar/pcaps/payloads/";

#$cfg_loc = "/tmp/payloads/conf/";
$pcap_loc = "/tmp/payloads/chksum";


$pcap_cfg{"ftp"} = "ftp.cfg";
$pcap_cfg{"apple"} = "apple.cfg";
$pcap_cfg{"smtp"} = "smtp.cfg";

$pcap_cfg{"nntp"} = "nntp.cfg";
$pcap_cfg{"akamai"} = "akamai.cfg";
$pcap_cfg{"amazon"} = "amazon.cfg";
$pcap_cfg{"battlefield"} = "battlefield.cfg";
$pcap_cfg{"cityofheroes"} = "cityofheroes.cfg";

$pcap_cfg{"cloudfront"} = "cloudfront.cfg";
$pcap_cfg{"dropbox"} = "dropbox.cfg";
$pcap_cfg{"msupdate"} = "msupdate.cfg";
$pcap_cfg{"gamespy"} = "gamespy.cfg";
$pcap_cfg{"git"} = "git.cfg";

$pcap_cfg{"gmail"} = "gmail.cfg";
$pcap_cfg{"hotmail"} = "hotmail.cfg";
$pcap_cfg{"icloud"} = "icloud.cfg";
$pcap_cfg{"mailchimp"} = "mailchimp.cfg";
$pcap_cfg{"ocsp"} = "ocsp.cfg";

$pcap_cfg{"svn"} = "svn.cfg";
$pcap_cfg{"imapssl"} = "imapssl.cfg";
$pcap_cfg{"irc"} = "irc.cfg";
$pcap_cfg{"msn"} = "msn.cfg";
$pcap_cfg{"mysql"} = "mysql.cfg";

$pcap_cfg{"pop3ssl"} = "pop3ssl.cfg";
$pcap_cfg{"rdp"} = "rdp.cfg";
$pcap_cfg{"smb"} = "smb.cfg";
$pcap_cfg{"vnc"} = "vnc.cfg";
$pcap_cfg{"yahoomessenger"} = "yahoomessenger.cfg";

#$session = Expect->new();

print "\n Test Started \n";
foreach (sort keys %pcap_cfg)
{
	
        #print $_ ," : " ,$pcap_cfg{$_}, "\n";
        
        %app_cfg = do "$cfg_loc".$pcap_cfg{"$_"};
=print 
			foreach (sort keys %app_cfg)
			{
				print $_ ," : " ,$app_cfg{$_}, "\n";
			}
=cut
		$cmd = "tcpreplay -i eth6 ".$pcap_loc."".$app_cfg{'pcap_file_name'}."_";
		
		print "\nPcap RUN Time : " . (floor($app_cfg{'duration'}) + 10) . "\n" ;
		print $session "date\n";
		print $session "$cmd\n";
		
		unless($session->expect(5, "processing file"))
		{
			print "failed at ".$pcap_loc."".$app_cfg{'pcap_file_name'}."\n";
			exit 0;
		}
		
		unless($session->expect((floor($app_cfg{'duration'}) + 10) , "Retried packets (EAGAIN):"))
		{
			print "failed to send all the packets ".$pcap_loc."".$app_cfg{'pcap_file_name'}."\n";
			exit 0;
		}
		print $session "date\n";
		#sleep (int($app_cfg{'duration'}) / 2 );
		
		print "\n Valar \n";
}
