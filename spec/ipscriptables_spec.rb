require 'spec_helper'

module IPScriptables
  describe "Ruleset.from_file" do
    Dir[File.join(FIXTURES, "**/*.txt")].each do |fixture|
      it "parses iptables-save output from #{File.basename(fixture)} and is able to render it back" do
        expect { Ruleset.from_file(fixture).render ==
          File.open(fixture).lines.reject { |ln| ln =~ /^#/ }.join }
      end
    end
  end

  describe "Ruleset#new" do
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
end
