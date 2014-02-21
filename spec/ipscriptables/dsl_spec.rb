# -*- coding: utf-8 -*-
require 'spec_helper'

module IPScriptables
  describe 'Chain#rule' do
    THREE_PORTS_RULES = <<EOF
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
-A INPUT -j REJECT --reject-with icmp-port-unreachable
COMMIT
EOF

    def expect_three_ports_from(&block)
      rs = Ruleset.new do
        table :filter do
          chain :INPUT do
            instance_eval(&block)
            rule '-j REJECT --reject-with icmp-port-unreachable'
          end
        end
      end
      expect { rs.render == THREE_PORTS_RULES }
    end

    it 'allows to describe rulesets' do
      expect_three_ports_from do
        rule '-p tcp -m tcp --dport 22 -j ACCEPT'
        rule '-p tcp -m tcp --dport 80 -j ACCEPT'
        rule '-p tcp -m tcp --dport 443 -j ACCEPT'
      end
    end

    it 'Allows nesting for DRY' do
      expect_three_ports_from do
        rule '-p tcp -m tcp' do
          rule '--dport 22 -j ACCEPT'
          rule '--dport 80 -j ACCEPT'
          rule '--dport 443 -j ACCEPT'
        end
      end
    end

    it 'accepts iterable of elements for iteration' do
      expect_three_ports_from do
        rule [
          '-p tcp -m tcp --dport 22 -j ACCEPT',
          '-p tcp -m tcp --dport 80 -j ACCEPT',
          '-p tcp -m tcp --dport 443 -j ACCEPT'
        ]
      end
    end

    it 'accepts multiple of arguments and processes them as if nested' do
      expect_three_ports_from do
        rule '-p tcp -m tcp --dport', [22, 80, 443], '-j ACCEPT'
      end
    end

    it 'understands parameters provided as hashes' do
      expect_three_ports_from do
        rule p: :tcp, m: :tcp, dport: [22, 80, 443], j: :ACCEPT
      end

      expect_three_ports_from do
        rule '-p' => :tcp, '-m' => :tcp, '--dport' => [22, 80, 443], '-j' => :ACCEPT # rubocop:disable LineLength
      end
    end
  end
end
