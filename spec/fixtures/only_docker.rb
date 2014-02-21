# -*- coding: utf-8 -*-

table :filter do
  chain :FORWARD do
    rule '-o docker0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT'
    rule '-i docker0 ! -o docker0 -j ACCEPT'
    rule '-i docker0 -o docker0 -j ACCEPT'
  end
end

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
