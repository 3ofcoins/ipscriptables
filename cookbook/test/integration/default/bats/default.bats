# -*- shell-script -*-

@test "there are iptables rules" {
    [ `iptables-save | wc -l` -gt 10 ]
}

@test "iptables entries are configured" {
    iptables-save | grep '^-A FWR -p tcp -m tcp --dport 22 -j ACCEPT$'
}
