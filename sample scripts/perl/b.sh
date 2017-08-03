
while (true)
do
        iperf -c 10.0.0.2 -t 10000 -b 5000K -d >> /tmp/iperf_test;
        sleep 5;
	iperf -c 10.0.0.2 -t 10000 >> /tmp/iperf_test;
	sleep 5;
done;

