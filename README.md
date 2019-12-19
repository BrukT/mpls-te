# QoS-diffserv
Traffic Engineering Using **Differentiated Service Code Point(DSCP)** protocol

In order to clone this repository you have to have the Git Large File Storage installed on your machine. also you have to instantiate your working directory with git lfs by:   
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; ```git lfs install```

The network is constructed and configured with GNS3 ide. 

use the follwing commands on the end point consols to test the resulting traffic load on router 5.

on servers :   
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; ``` iperf -u -s -i 1```

on clients :  
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; ``` iperf -u -c <server-ip-to-communicate> -t 20 -b <data-size> -i 1 ```

the data size above can be set to various ranges from small to large to see the run time bandwidth of each flows
