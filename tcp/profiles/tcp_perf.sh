#!/bin/bash

declare -i pid
declare -i timeout="${1}"
declare -i delay="${2}"

declare -a filenames=(
    'tcp_ipv4_loopback_tx_perf'
    'tcp_ipv4_loopback_tx_with_zerocopy_perf'
    'tcp_ipv4_loopback_rx_perf'

    'tcp_ipv4_tx_perf'
    'tcp_ipv4_tx_with_zerocopy_perf'
    'tcp_ipv4_rx_perf'

    'tcp_ipv6_loopback_tx_perf'
    'tcp_ipv6_loopback_tx_with_zerocopy_perf'
    'tcp_ipv6_loopback_rx_perf'

    'tcp_ipv6_tx_perf'
    'tcp_ipv6_tx_with_zerocopy_perf'
    'tcp_ipv6_rx_perf'
)

declare -A generators=(
    ['tcp_ipv4_loopback_tx_perf']="-4 -c localhost -N"
    ['tcp_ipv4_loopback_tx_with_zerocopy_perf']="-4 -c localhost -Z -N"
    ['tcp_ipv4_loopback_rx_perf']="-4 -c localhost -R"

    ['tcp_ipv4_tx_perf']="-4 -c fct-1-0c -N"
    ['tcp_ipv4_tx_with_zerocopy_perf']="-4 -c fct-1-0c -Z -N"
    ['tcp_ipv4_rx_perf']="-4 -c fct-1-0c -R"

    ['tcp_ipv6_loopback_tx_perf']="-6 -c localhost -N"
    ['tcp_ipv6_loopback_tx_with_zerocopy_perf']="-6 -c localhost -Z -N"
    ['tcp_ipv6_loopback_rx_perf']="-6 -c localhost -R"

    ['tcp_ipv6_tx_perf']="-6 -c fct0s2icom -N"
    ['tcp_ipv6_tx_with_zerocopy_perf']="-6 -c fct0s2icom -Z -N"
    ['tcp_ipv6_rx_perf']="-6 -c fct0s2icom -R"
)

function run_iperf3 {
    iperf3 ${generators[${1}]} -t  "$(( delay*2 + timeout ))" &
    pid=${!}
}

function run_perf {
    perf record -o "${1}.data" -F 99 -p "${2}" -g -- sleep "${timeout}"
}

function result {
    perf report -i "${1}.data" --stdio --no-children -n -g folded,0,caller,count -s comm | awk '/^ / { comm = $3 } /^[0-9]/ { print comm ";" $2, $1 }' > "${1}.mid"
}

for file in "${filenames[@]}"; do
    echo "Doing ${file} ..."
    run_iperf3 "${file}"
    sleep "${delay}"
    run_perf "${file}" "${pid}"
    wait
    result "${file}"
    echo "${file} has finished ..."
done
