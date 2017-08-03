#!/usr/bin/perl


$build_url_base="http://192.168.1.203/builds/integ_builds/latest_integ_build/";

`rm latest_build*; > /dev/null 2>&1`;

`wget -q --user=guest --password=testpass $build_url_base --no-check-certificate --output-document latest_build.html`;
$eagle_rpm_name=`cat latest_build.html | grep -re "eagle-x86-.*x86_64.rpm"`; 
$start = index($eagle_rpm_name,"eagle");
$end = index($eagle_rpm_name,"\">eagle");
$eagle_version = substr($eagle_rpm_name,$start,($end - $start));

print $eagle_version."\n\n";
