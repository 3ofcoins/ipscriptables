# -*- coding: utf-8 -*-
require 'spec_helper'

module IPScriptables
  describe 'Rule' do
    let(:chain) do
      ch = mock(Chain.name)
      ch.expects(:original).at_least_once.returns(nil)
      ch.expects(:opts).at_least(0).returns({})
      ch
    end

    let(:rule) do
      Rule.new(chain, '-s 1.1.1.1/32 -p tcp -m tcp -m multiport --dports 4949,5666 -j ACCEPT') # rubocop:disable LineLength
    end

    it 'allows accessing individual switches by dict access' do
      expect { rule['--dports'] == '4949,5666' }
      expect { rule['dports'] == '4949,5666' }
      expect { rule[:dports] == '4949,5666' }
      expect { rule[:destination_ports] == '4949,5666' }
      expect { rule[:j] == 'ACCEPT' }
      expect { rule[:jump] == 'ACCEPT' }
    end

    it 'rolls multiple options into arrays' do
      expect { rule[:m] == %w(tcp multiport) }
    end

    it 'has convenience aliases' do
      expect { rule.match == %w(tcp multiport) }
      expect { rule.proto == 'tcp' }
      expect { rule.target == 'ACCEPT' }
    end

    it 'can be also matched by regexp' do
      expect { rule =~ /multiport/ }
      deny   { rule =~ /udp/ }
    end
  end
end
