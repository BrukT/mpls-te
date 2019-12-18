ping 10.0.2.2
ip addr
ping 10.0.2.2
iperf -u -s -i 1
iperf -u -c 10.0.2.2 -i 1 -b 1M -t 20
iperf -u -c 10.0.2.3 -i 1 -b 1M -t 20
iperf -u -c 10.0.2.2 -i 1 -b 1M -t 20
iperf -u -c 10.0.2.3 -i 1 -b 1M -t 20
iperf -u -c 10.0.2.3 -i 1 -b 1.3M -t 20
iperf -u -c 10.0.2.3 -i 1 -b 5M -t 20
iperf -u -c 10.0.2.3 -i 1 -b 500K -t 90
iperf -u -c 10.0.2.3 -i 1 -b 1.3M -t 20
iperf -u -c 10.0.2.3 -i 1 -b 1.3M -t 90
iperf -u -c 10.0.2.3 -i 1 -b 1M -t 90
