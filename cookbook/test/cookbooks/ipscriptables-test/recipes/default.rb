# -*- coding: utf-8 -*-
# rubocop:disable LineLength

include_recipe 'ipscriptables-test::prepare'

ipscriptables do
  iptables do
    table :filter do
      chain :INPUT do
        rule :j => :FWR
      end

      chain :FWR do
        rule m: 'state', state: 'RELATED,ESTABLISHED', j: 'ACCEPT'
        rule i: ['lo', 'docker+'], j: 'ACCEPT'
        rule '-p icmp -j ACCEPT'
        rule '-p tcp -m tcp --dport', 22, '-j ACCEPT'
        rule '-p tcp -m tcp --tcp-flags SYN,RST,ACK SYN -j REJECT --reject-with icmp-port-unreachable'
        rule '-p udp -j REJECT --reject-with icmp-port-unreachable'
      end
    end
  end
end
