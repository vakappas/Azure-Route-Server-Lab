#!/bin/bash

# Deploy baseline VPN and BGP config to a Cisco CSR
function config_csr_base () {
    csr_id=$1
    csr_ip=$(az network public-ip show -n "csr${csr_id}-pip" -g "$rg" -o tsv --query ipAddress 2>/dev/null)
    asn=$(get_router_asn_from_id "$csr_id")
    myip=$(curl -s4 ifconfig.co)
    # Check we have a valid IP
    until [[ $myip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]
    do
        sleep 5
        myip=$(curl -s4 ifconfig.co)
    done
    echo "Our IP seems to be $myip"
    default_gateway="10.${csr_id}.0.1"
    echo "Configuring CSR ${csr_ip} for VPN and BGP..."
    username=$(whoami)
    password=$psk
    ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o KexAlgorithms=+diffie-hellman-group14-sha1 "$csr_ip" >/dev/null 2>&1 <<EOF
    config t
      username ${username} password 0 ${password}
      username ${username} privilege 15
      username ${default_username} password 0 ${password}
      username ${default_username} privilege 15
      no ip domain lookup
      no ip ssh timeout
      crypto ikev2 keyring azure-keyring
      crypto ikev2 proposal azure-proposal
        encryption aes-cbc-256 aes-cbc-128 3des
        integrity sha1
        group 2
      crypto ikev2 policy azure-policy
        proposal azure-proposal
      crypto ikev2 profile azure-profile
        match address local interface GigabitEthernet1
        authentication remote pre-share
        authentication local pre-share
        keyring local azure-keyring
      crypto ipsec transform-set azure-ipsec-proposal-set esp-aes 256 esp-sha-hmac
        mode tunnel
      crypto ipsec profile azure-vti
        set security-association lifetime kilobytes 102400000
        set transform-set azure-ipsec-proposal-set
        set ikev2-profile azure-profile
      crypto isakmp policy 1
        encr aes
        authentication pre-share
        group 14
      crypto ipsec transform-set csr-ts esp-aes esp-sha-hmac
        mode tunnel
      crypto ipsec profile csr-profile
        set transform-set csr-ts
      router bgp $asn
        bgp router-id interface GigabitEthernet1
        network 10.${csr_id}.0.0 mask 255.255.0.0
        bgp log-neighbor-changes
        maximum-paths eibgp 4
      ip route ${myip} 255.255.255.255 ${default_gateway}
      ip route 10.${csr_id}.0.0 255.255.0.0 ${default_gateway}
      line vty 0 15
        exec-timeout 0 0
    end
    wr mem
EOF
}