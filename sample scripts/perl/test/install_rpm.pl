#!/usr/bin/perl
use POSIX qw/strftime/;

# Dirs
$root_dir = "/opt/eagle/";
$db_updates_dir = $root_dir . "/db_updates/";
$build_dir = "/opt/.eagle_build/";
$db_lock = $build_dir . "/db_lock";
$success_file = $build_dir . "/success_file";
$dld_dir = $build_dir . "rpms/";
$freset_flag_file = $build_dir . "/freset_flag_file";
$current_build = $build_dir . "current_bld";
$prev_build = $build_dir . "previous_bld";
$fac_build = $build_dir . "factory_bld";
$dld_build = $build_dir . "dld_bld";
$log_file = "/var/log/eagle_init.log";

sub print_log($$) {
        open $log, ">>".$log_file;
        my($show_on_screen, $msg) = @_;
        my $times = strftime('%d-%b-%Y %H:%M:%S',localtime);
        print $log $times . " " . $msg;
        if($show_on_screen == 1) {
                print $times . " " . $msg;
        }
        close($log);
}

sub trim($)
{
        my $string = shift;
        $string =~ s/^[\s\t]+//;
        $string =~ s/[\s\t]+$//;
        return $string;
}

sub get_version($) {
        my ($rpm_file) = @_;
        $result = `sudo rpm -qip $rpm_file >> $log_file 2>&1`;
        $rets = $?;
        if ($rets != 0) {
                print_log(1, "Error: Not able to find $rpm_file version \n" . $result);
                return "";
        }

        $cmd = "sudo rpm -qip $rpm_file  | grep -i version | cut -d':' -f2";
        $version = `$cmd`;
	print_log(0, "Got build version as $version\n");
        chomp($version);
        if ($version == '' ) {
                print_log(1, "Error: Not able to get $rpm_file version \n" . $result);
                return "";
        }
        $cmd = "sudo rpm -qip $rpm_file  | grep -i Release | awk -F\": \" '{print \$2}'";
        $release = `$cmd`;
	print_log(0, "Got build release as $release\n");
        chomp($release);
        if ($release eq "" ) {
                print_log(1, "Error: Not able to get $rpm_file release \n" . $result);
                return "";
        }
        return trim($version."-".$release);
}
=pod
sub get_octbin_version() {
        my ($rpm_file) = "octbin";
        $result = `sudo rpm -qi $rpm_file >> $log_file 2>&1`;
        $rets = $?;
        if ($rets != 0) {
                print_log(1, "Error: Not able to find $rpm_file version \n" . $result);
                return "";
        }

        $cmd = "sudo rpm -qi $rpm_file  | grep -i version | cut -d':' -f2";
        $version = `$cmd`;
        print_log(0, "Got build version as $version\n");
        chomp($version);
        if ($version == '' ) {
                print_log(1, "Error: Not able to get $rpm_file version \n" . $result);
                return "";
        }
        $cmd = "sudo rpm -qi $rpm_file  | grep -i Release | awk -F\": \" '{print \$2}'";
        $release = `$cmd`;
        print_log(0, "Got build release as $release\n");
        chomp($release);
        if ($release == '' ) {
                print_log(1, "Error: Not able to get $rpm_file release \n" . $result);
                return "";
        }
        return trim($version."-".$release);
}
=cut
sub get_build_time($) {
        my ($rpm_file) = @_;
        $result = `sudo rpm -qip $rpm_file >> $log_file 2>&1`;
        $rets = $?;
        if ($rets != 0) {
                print_log(1, "Error: Not able to find $rpm_file version \n" . $result);
                return "";
        }

        $cmd = "sudo rpm -qip $rpm_file  | grep -i 'Build Date' | awk -F\": \" '{print \$2}'";
        $build_time = `$cmd`;
	print_log(0, "Got build time as $build_time\n");
        return trim($build_time);
}

if ($#ARGV != 0 ) {
        print_log (1, "Usage: install_rpm.pl <path-to-rpm-file>\n");
        exit 1;
}
$rpm_file = $ARGV[0];
$filename = `basename $rpm_file`;
chomp($filename);

# Setup required dirs
`rm -fr $build_dir  >> $log_file 2>&1`;
`mkdir -p $dld_dir >> $log_file 2>&1`;
$result = `rpm -ivh $rpm_file  >> $log_file 2>&1`;
$rets = $?;
if ($rets != 0) {
        print_log(1, "Error: Not able to install $rpm_file\n" . $result);
        exit $rets;
}
sleep(2);
print_log(1, "Installing $rpm_file success\n");

`rm -f $current_build $fac_build`;
`cp -fr $rpm_file $dld_dir/$filename`;
`ln -s $dld_dir/$filename $current_build`;
`ln -s $dld_dir/$filename $fac_build`;

$factory_version = get_version($rpm_file);
`rm -f /tmp/db_cmd >> $log_file 2>&1`;
$cmd = "update system_config set value=\'" . $factory_version . "\' where key='cur_rpm_version'";
open(OUT,">/tmp/db_cmd");
print OUT $cmd;
close(OUT);
print_log(0, "$cmd\n");
$result = `sudo -i -u postgres -H sh -c "psql -d eagle_db -f /tmp/db_cmd" >> $log_file 2>&1`;
$rets = $?;
if ($rets != 0) {
        print_log(1,  "Error: Not able to set imagename_factory\n" . $result);
        exit $rets;
}

$cmd = "update system_config set value=\E'" . $factory_version . "' where key='factory_rpm_version'";
open(OUT,">/tmp/db_cmd");
print OUT $cmd;
close(OUT);
print_log(0, "$cmd\n");
$result = `sudo -i -u postgres -H sh -c "psql -d eagle_db -f /tmp/db_cmd" >> $log_file 2>&1`;
$rets = $?;
if ($rets != 0) {
        print_log(1,  "Error: Not able to set imagename_running \n" . $result);
        exit $rets;
}

$fac_build_time= get_build_time($rpm_file);
$cmd = "update system_config set value=\E'" . $fac_build_time . "' where key='imagename_factory_time'";
open(OUT,">/tmp/db_cmd");
print OUT $cmd;
close(OUT);
print_log(0, "$cmd\n");
$result = `sudo -i -u postgres -H sh -c "psql -d eagle_db -f /tmp/db_cmd" >> $log_file 2>&1`;
$rets = $?;
if ($rets != 0) {
        print_log(1,  "Error: Not able to set imagename_factory_time\n" . $result);
        exit $rets;
}

$cmd = "update system_config set value=\E'" . $fac_build_time . "' where key='cur_build_time'";
open(OUT,">/tmp/db_cmd");
print OUT $cmd;
close(OUT);
print_log(0, "$cmd\n");
$result = `sudo -i -u postgres -H sh -c "psql -d eagle_db -f /tmp/db_cmd" >> $log_file 2>&1`;
$rets = $?;
if ($rets != 0) {
        print_log(1,  "Error: Not able to set cur_build_time\n" . $result);
        exit $rets;
}

$install_time = strftime('%a %d %b %Y %I:%M:%S %p %Z',localtime);
$cmd = "update system_config set value=\E'" . $install_time. "' where key='sysimg_inst_time'";
open(OUT,">/tmp/db_cmd");
print OUT $cmd;
close(OUT);
print_log(0, "$cmd\n");
$result = `sudo -i -u postgres -H sh -c "psql -d eagle_db -f /tmp/db_cmd" >> $log_file 2>&1`;
$rets = $?;
if ($rets != 0) {
        print_log(1,  "Error: Not able to set sysimg_inst_time\n" . $result);
        exit $rets;
}
=pod
$octbin_version = get_octbin_version();
`rm -f /tmp/db_cmd >> $log_file 2>&1`;
$cmd = "update system_config set value=\'" . $octbin_version . "\' where key='oct_rpm_version'";
open(OUT,">/tmp/db_cmd");
print OUT $cmd;
close(OUT);
print_log(0, "$cmd\n");
$result = `sudo -i -u postgres -H sh -c "psql -d eagle_db -f /tmp/db_cmd" >> $log_file 2>&1`;
$rets = $?;
if ($rets != 0) {
        print_log(1,  "Error: Not able to set oct_rpm_version\n" . $result);
        exit $rets;
}
$result = `sudo -i -u postgres -H sh -c "pg_dump -c eagle_db > /tmp/db_dump"`;
$rets = $?;
if ($rets != 0) {
        print_log(1, "Error: Not able to current snapshot of DB\n" . $result);
	exit $rets;
}
`sudo mv /tmp/db_dump $db_dump >> $log_file 2>&1`;

=cut
print_log(1, "DB updated successfully\n");
