# QoS-diffserv
Traffic Engineering Using Multi Packet Label Switching protocol

use the follwing commands to test the traffic load on router 5

on servers ``` iperf -u -s -i 1```

on clients ``` iperf -u -c <server-ip-to-communicate> -t 20 -b <data-size> -i 1 ```

the data size above can be set to various ranges from small to large to see the run time bandwidth of each flows
