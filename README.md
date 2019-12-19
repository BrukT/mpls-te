# Differentiated Service Architecture for QoS support

## Network Architecture

The network is built and configured with GNS3 ide. It is recommended to use the same software for testing it. 

[!Scenario]

The above scenario shows three networks interconnected through a core network of 5 routers. Each network contains either _Client_ nodes (`A1`, `A2`, `C1`) or _Server_ nodes (`B1`, `B2`). Clients send data to servers and have the flow characteristics that are shown in the following table:

| Source | Destination | Priority | Bandwidth |
--- | --- | --- | ---
A1 | B1 | High | 0.9Mbps
A2 | B2 | Low | 1.2Mbps
C1 | B1 | High | 0.9Mbps

### Goals

- each flow conforms to the characteristics of Table. For high-priority flows, the excess traffic is downgraded to low priority; for low-priority flows, the excess traffic is dropped.

- Each high-priority flow is granted at worst 60% of the bandwidth for the link it traverses in the core network.

## Configuration

The following Table represents the address assignation for the networks:

| Net | Address | Subnet mask |
--- | --- | ---
A | 10.0.1.0 | 255.255.255.0
B | 10.0.2.0 | 255.255.255.0
C | 10.0.3.0 | 255.255.255.0
R1-R2 | 172.16.0.0 | 255.255.255.252
R1-R3 | 172.16.4.0 | 255.255.255.252
R2-R5 | 172.16.8.0 | 255.255.255.252
R3-R4 | 172.16.12.0 | 255.255.255.252
R4-R5 | 172.16.16.0 | 255.255.255.252

For the IPs assigned to the router interfaces you can refer to the picture shown above.

In order to achive the flow characteristics, we decided to configure the IP address of hosts in `Network-A` and `Network-B` statically. Instead we configured DHCP service on `R2` since it has only one host in its subnetwork.

Futhermore, for each router we configured the `Loopback0` interface which will be used as `router-id` attribute in the OSPF protocol.

### OSPF

We chose OSPF as routing protocol since it is ready for the implementation of other services such as MPLS-TE (but it is not our goal right now).

Every router has been configured in order to be able to announce all the network to which it is attached and we used the following IOS commands:

```
R(config)# router ospf 1
R(config)# network <network-address> <wildcard-mask> area 0
```

### Packet Classification

In order to classificate the flows based on source and destination we used _Extendend Access Control Lists_ and we put them in the nearest router to the source. Thus, we defined three ACLs accordingly to the three different flows we have to match.

On `R1` we defined an ACL with id `121` for traffic from `A1` to `B1`:

```
R1(config)# access-list 121 permit ip host 10.0.1.2 host 10.0.2.2
R1(config-cmap)# class-map match-all A1B1
R1(config-cmap-c)# match access-group 121
```

and an ACL with id `122` for traffic from `A2` to `B2`:

```
R1(config)# access-list 122 permit ip host 10.0.1.3 host 10.0.2.3
R1(config-cmap)# class-map match-all A2B2
R1(config-cmap-c)# match access-group 122
```

On `R2` we defined an ACL with id `121` for traffic from `C1` to `B1`:

```
R2(config)# access-list 121 permit ip host 10.0.3.2 host 10.0.2.2
R2(config-cmap)# class-map match-all C1B1
R2(config-cmap-c)# match access-group 121
```

### Packet Marking

For differentiating the two types of flow we assigned different _Per Hob Behavior_ as shown in the following table:

| Priority | PHB | DSCP |
--- | ---
High | EF | 46
Low | AF13 | 14

In the relative routers we defined marking for the classes like this:



## Clone repository

In order to clone this repository you have to have the Git Large File Storage installed on your machine. also you have to instantiate your working directory with git lfs by:   
```
git lfs install
```

 
## Troubleshooting

Use the follwing commands on the end point consols to test the resulting traffic load on router 5.

on servers:   
```
iperf -u -s -i 1
```

on clients:  

``` 
iperf -u -c <server-ip-to-communicate> -t 20 -b <data-size> -i 1 
```

The data size above can be set to various ranges from small to large to see the run time bandwidth of each flows.
