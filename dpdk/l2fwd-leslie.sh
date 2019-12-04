#!/bin/bash

if [ ${USER} != "root" ]
then
    echo "${0}: Permission denied" 1>&2

    exit 1
fi

RTE_SDK="${HOME}/dpdk"
RTE_TARGET="x86_64-native-linuxapp-gcc"

VIRTUAL_INTERFACES+=" --vdev=net_tap0,iface=ethc"
VIRTUAL_INTERFACES+=" --vdev=net_tap1,iface=eths"

EAL_PARAMS="-c 0xf -n 4 ${VIRTUAL_INTERFACES}"

DPDK_APP="${RTE_SDK}/examples/l2fwd/build/l2fwd"
DPDK_APP_PARAMS="-p 0x3 --no-mac-updating"

${DPDK_APP} ${EAL_PARAMS} -- ${DPDK_APP_PARAMS} &

sleep 2

pids+=($(ip netns pids client 2> /dev/null))
pids+=($(ip netns pids server 2> /dev/null))

kill ${pids[@]} 2> /dev/null

ip netns delete client 2> /dev/null
ip netns delete server 2> /dev/null

ip netns add client
ip netns add server

ip link set ethc netns client
ip link set eths netns server

ip netns exec client ip link set lo up
ip netns exec server ip link set lo up

ip netns exec client ip link set ethc up
ip netns exec server ip link set eths up

ip netns exec client ip address add 10.0.0.1/24 dev ethc
ip netns exec server ip address add 10.0.0.2/24 dev eths

wait
