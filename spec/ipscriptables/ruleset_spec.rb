require 'spec_helper'

module IPScriptables
  describe "Ruleset#method_missing" do
    let(:rs) { Ruleset.new(foo: 23) }
    it "forwards calls to ruleset's options" do
      expect { rs.foo == 23 }
      expect { rs.respond_to? :foo }
    end

    it "rejects methods that are not in options" do
      expect { rescuing { rs.bar }.is_a?(NoMethodError) }
      deny   { rs.respond_to? :bar }
    end
  end

  describe "Ruleset#bud" do
    let(:drumknott) { Ruleset.from_file(fixture("drumknott.txt")) }
    let(:ghq)       { Ruleset.from_file(fixture("ghq.txt")) }

    it "creates a child ruleset with identical tables and chains, but no rules" do
      expected_rules = <<-EOF
*mangle
:PREROUTING ACCEPT [9070264:2761485141]
:INPUT ACCEPT [5794:541194]
:FORWARD ACCEPT [9064470:2760943947]
:OUTPUT ACCEPT [4447:1027385]
:POSTROUTING ACCEPT [9068917:2761971332]
COMMIT
*nat
:PREROUTING ACCEPT [936831:58138468]
:INPUT ACCEPT [383149:28442596]
:OUTPUT ACCEPT [188115:19311882]
:POSTROUTING ACCEPT [88176135:5298607741]
:DOCKER - [0:0]
COMMIT
*filter
:INPUT ACCEPT [419:18560]
:FORWARD ACCEPT [5802508472:1613710597740]
:OUTPUT ACCEPT [2072879:485657573]
:FWR - [0:0]
COMMIT
        EOF
      child = drumknott.bud
      expect { child.render == expected_rules }
      expect { child.original == drumknott }
    end

    it "allows chain inheritance" do
      child = drumknott.bud do
        inherit :nat, :DOCKER
      end
      expected_rules = <<-EOF
*mangle
:PREROUTING ACCEPT [9070264:2761485141]
:INPUT ACCEPT [5794:541194]
:FORWARD ACCEPT [9064470:2760943947]
:OUTPUT ACCEPT [4447:1027385]
:POSTROUTING ACCEPT [9068917:2761971332]
COMMIT
*nat
:PREROUTING ACCEPT [936831:58138468]
:INPUT ACCEPT [383149:28442596]
:OUTPUT ACCEPT [188115:19311882]
:POSTROUTING ACCEPT [88176135:5298607741]
:DOCKER - [0:0]
-A DOCKER ! -i docker0 -p tcp -m tcp --dport 6379 -j DNAT --to-destination 172.17.0.2:6379
COMMIT
*filter
:INPUT ACCEPT [419:18560]
:FORWARD ACCEPT [5802508472:1613710597740]
:OUTPUT ACCEPT [2072879:485657573]
:FWR - [0:0]
COMMIT
        EOF
      expect { child.render == expected_rules }
    end

    it "allows filtering inherited chains" do
      child = drumknott.bud do
        inherit(:filter, :FWR) { |rule| !rule[:source] }
      end
      expected_rules = <<-EOF
*mangle
:PREROUTING ACCEPT [9070264:2761485141]
:INPUT ACCEPT [5794:541194]
:FORWARD ACCEPT [9064470:2760943947]
:OUTPUT ACCEPT [4447:1027385]
:POSTROUTING ACCEPT [9068917:2761971332]
COMMIT
*nat
:PREROUTING ACCEPT [936831:58138468]
:INPUT ACCEPT [383149:28442596]
:OUTPUT ACCEPT [188115:19311882]
:POSTROUTING ACCEPT [88176135:5298607741]
:DOCKER - [0:0]
COMMIT
*filter
:INPUT ACCEPT [419:18560]
:FORWARD ACCEPT [5802508472:1613710597740]
:OUTPUT ACCEPT [2072879:485657573]
:FWR - [0:0]
-A FWR -i lo -j ACCEPT
-A FWR -m state --state RELATED,ESTABLISHED -j ACCEPT
-A FWR -p icmp -j ACCEPT
-A FWR -i docker+ -j ACCEPT
-A FWR -p tcp -m tcp --dport 22 -j ACCEPT
-A FWR -p tcp -m tcp --tcp-flags SYN,RST,ACK SYN -j REJECT --reject-with icmp-port-unreachable
-A FWR -p udp -j REJECT --reject-with icmp-port-unreachable
COMMIT
        EOF
      expect { child.render == expected_rules }
      expect { drumknott.render =~ /^-A FWR -s 1\.1\.1\.1/ }
    end

    it "copies original's chain with counters" do
      child = ghq.bud do
        inherit(:nat, :DOCKER)
        table :filter do
          chain :INPUT do
            rule '-j FWR'
          end
          chain :FWR do
            rule '-i lo -j ACCEPT'
          end
        end
      end

      expected_rules = <<-EOF
*nat
:PREROUTING ACCEPT [732601:44001989]
:INPUT ACCEPT [376018:22538408]
:OUTPUT ACCEPT [3131507:229597576]
:POSTROUTING ACCEPT [20476198:1943580383]
:DOCKER - [0:0]
[2:120] -A DOCKER ! -i docker0 -p tcp -m tcp --dport 2003 -j DNAT --to-destination 172.17.0.4:2003
[0:0] -A DOCKER ! -i docker0 -p tcp -m tcp --dport 2004 -j DNAT --to-destination 172.17.0.4:2004
[0:0] -A DOCKER ! -i docker0 -p tcp -m tcp --dport 49153 -j DNAT --to-destination 172.17.0.8:9000
[95:5580] -A DOCKER ! -i docker0 -p tcp -m tcp --dport 5000 -j DNAT --to-destination 172.17.0.5:5000
[0:0] -A DOCKER -d 127.0.0.1/32 ! -i docker0 -p tcp -m tcp --dport 49154 -j DNAT --to-destination 172.17.0.9:8080
[17011603:1693997647] -A DOCKER ! -i docker0 -p udp -m udp --dport 8125 -j DNAT --to-destination 172.17.0.10:8125
[0:0] -A DOCKER -d 127.0.0.1/32 ! -i docker0 -p tcp -m tcp --dport 49155 -j DNAT --to-destination 172.17.0.10:8126
COMMIT
*filter
:INPUT ACCEPT [1602:65593]
:FORWARD ACCEPT [79892700:14079015733]
:OUTPUT ACCEPT [173177551:46244981637]
:FWR - [0:0]
[162824485:36484450187] -A INPUT -j FWR
[104747465:21902005069] -A FWR -i lo -j ACCEPT
COMMIT
      EOF

      expect { child.render == expected_rules }
    end
  end

  describe "Ruleset#diff" do
    it "returns a Diffy::Diff from the original ruleset" do
      child = Ruleset.from_file(fixture("only-docker.txt")).bud

      expect { child.diff.to_s.each_line.grep(/^\S/).length == 7 }

      child.dsl_eval do
        inherit :filter, :FORWARD
      end

      expect { child.diff.to_s.each_line.grep(/^\S/).length == 4 }

      child.dsl_eval do
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

      expect { child.diff.to_s.empty? }
    end
  end

  describe "Ruleset#load_file" do
    it "Loads a ruleset from file" do
      child = Ruleset.from_file(fixture("only-docker.txt")).bud
      deny { child.diff.to_s.empty? }
      child.load_file fixture('only_docker.rb')
      expect { child.diff.to_s.empty? }
    end
  end
end
