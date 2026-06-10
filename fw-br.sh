echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
yum install -y nftables
cat > /etc/nftables/nat.nft << 'EOF'
table ip nat {
    chain POSTROUTING {
        type nat hook postrouting priority srcnat + 20;
        policy accept;
        ip saddr 172.26.197.96/27 oifname "ens192" masquerade
    }
}
EOF
echo 'include "/etc/nftables/nat.nft"' >> /etc/sysconfig/nftables.conf
systemctl enable nftables
systemctl restart nftables
ip tunnel add gre1 mode gre local 10.118.152.254 remote 10.15.0.100 ttl 255
ip addr add 10.200.176.2/30 dev gre1
ip link set gre1 up
ip route add 192.168.239.96/27 via 10.200.176.1
cat > /etc/sysconfig/network-scripts/ifcfg-gre1 << 'EOF2'
DEVICE=gre1
BOOTPROTO=none
ONBOOT=yes
TYPE=GRE
MY_INNER_IPADDR=10.200.176.2
PREFIX=30
MY_OUTER_IPADDR=10.118.152.254
PEER_OUTER_IPADDR=10.15.0.100
EOF2
cat > /etc/sysconfig/network-scripts/route-gre1 << 'EOF3'
192.168.239.96/27 via 10.200.176.1
EOF3
