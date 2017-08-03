
while (true) 
do
	httperf --server 10.0.0.2 --uri /Guide.html --rate 10 --num-conn 100 --timeout 5 --num-calls 5 >> /tmp/httperf_test;
	sleep 5; 
done;
