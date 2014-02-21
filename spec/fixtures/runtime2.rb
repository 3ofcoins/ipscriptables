# -*- coding: utf-8 -*-

iptables do
  table :nat do
    chain :PREROUTING do
      rule '-m addrtype --dst-type LOCAL -j DOCKER'
    end
    chain :OUTPUT do
      rule '! -d 127.0.0.0/8 -m addrtype --dst-type LOCAL -j DOCKER'
    end
    chain :POSTROUTING do
      rule '-s 172.17.0.0/16 ! -d 172.17.0.0/16 -j MASQUERADE'
      rule '-s 10.0.3.0/24 ! -d 10.0.3.0/24 -j MASQUERADE'
    end
  end
end
