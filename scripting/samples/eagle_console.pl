#!/usr/bin/perl

use perl_modules::common;

execute(load_config("207"));

$ssh = execute_ssh(login("192.168.1.207", "root", "testpass"));

collect_dpconsole_output($ssh,("pmdump", "classdump nzask"));
#collect_dpconsole_output($ssh,("pmdump", "classdump nzask", "classdump nzdrop", "pmdebug", "flowdump ipv4 all", "pmdebug", "classdump nzqueue", "classdump nzrate", "pmdebug", "memusage", "hmon"));
#collect_dpconsole_output($ssh,("pmdump", "classdump nzask", "classdump nzdrop", "pmdebug", "flowdump ipv4 all", "pmdebug", "classdump nzqueue", "classdump nzrate", "pmdebug", "memusage", "hmon"));
$ssh->send("date\n");
$ssh->expect(10, "valar");

my $subject = "Sanity Tests Finished for build # $version{'ver_current'}";
my $body_text = "Please find attached output and log files for the build sanity test results.";
# send email after sanity test
send_mail("$subject", "$body_text", "attach logs");
$ssh->close();
