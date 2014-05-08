# -*- coding: utf-8 -*-
require 'spec_helper'

module IPScriptables
  describe 'Ruleset.from_file, .from_s' do
    Dir[fixture('**/*.txt')].each do |fixture|
      it "parses #{File.basename(fixture)} and renders it back" do
        fixture_text = File.open(fixture).lines.grep(/^[^#]/).join
        expect { Ruleset.from_file(fixture).render == fixture_text }
        expect { Ruleset.from_s(File.read(fixture)).render == fixture_text }
      end
    end

    it 'fails on invalid input' do
      expect { rescuing { Ruleset.from_s('Invalid!') }.is_a?(RuntimeError) }
    end
  end

  describe 'Ruleset.from_command' do
    let(:fixture_content) { File.read(fixture('ghq.txt')) }
    let(:fixture_text) { fixture_content.lines.grep(/^[^#]/).join }

    it 'executes external command and parses its output as ruleset' do
      Helpers.expects(:run_command)
        .with('a', 'command', 'with', 'arguments')
        .returns(fixture_content)
      rs = Ruleset.from_command('a', 'command', 'with', 'arguments')
      expect { rs.render == fixture_text }
      expect { rs.command == %w(a command with arguments) }
    end

    it 'has a convenience alias .from_iptables' do
      Helpers.expects(:run_command)
        .with('iptables-save', '-c')
        .returns(fixture_content)
      rs = Ruleset.from_iptables
      expect { rs.render == fixture_text }
      expect { rs.command == %w(iptables-save -c) }
      expect { rs.family == :inet }
    end

    it 'has a convenience alias .from_ip6tables' do
      Helpers.expects(:run_command)
        .with('ip6tables-save', '-c')
        .returns(fixture_content)
      rs = Ruleset.from_ip6tables
      expect { rs.render == fixture_text }
      expect { rs.command == %w(ip6tables-save -c) }
      expect { rs.family == :inet6 }
    end
  end
end
