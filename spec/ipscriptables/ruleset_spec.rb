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

  describe "Ruleset#initialize" do
    it "allows to create rulesets with a DSL" do
      rs = Ruleset.new do
        table :filter do
          chain :INPUT do
            rule '-p tcp -m tcp --dport 22 -j ACCEPT'
            rule '-j REJECT --reject-with icmp-port-unreachable'
          end
        end
      end

      expected_rules = <<-EOF
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
-A INPUT -j REJECT --reject-with icmp-port-unreachable
COMMIT
        EOF

      expect { rs.render == expected_rules }
    end
  end

  describe "Ruleset#bud" do
    let(:drumknott) { Ruleset.from_file(fixture("drumknott.txt")) }
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
        inherit(:filter, :FWR) { |rule| rule !~ /^-s/ }
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
  end
end
