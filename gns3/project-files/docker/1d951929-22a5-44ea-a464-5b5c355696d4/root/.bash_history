ping 172.16.0.17
ping 10.0.3.1
ping 172.16.0.4
ping 172.16.0.17
ping 10.0.2.2
ping 10.0.2.3
ping 10.0.1.3
exit
ping 10.0.1.3
ping 10.0.2.3
ping 10.0.2.2
iperf -u -c 10.0.2.2 -i 1 -t 20 -b 1
iperf -u -c 10.0.2.2 -i 1 -t 20 -b 1M
iperf -u -c 10.0.2.2 -i 1 -t 20 -b 500K
iperf -u -c 10.0.2.2 -i 1 -t 20 -b 1000K
iperf -u -c 10.0.2.2 -i 1 -t 20 -b 2M
iperf -u -c 10.0.2.2 -i 1 -t 90 -b 500K
