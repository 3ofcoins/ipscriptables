require 'spec_helper'

module IPScriptables
  describe "Ruleset.from_file, .from_s" do
    Dir[fixture("**/*.txt")].each do |fixture|
      it "parses #{File.basename(fixture)} and renders it back" do
        stripped_fixture = File.open(fixture).lines.reject { |ln| ln =~ /^#/ }.join
        expect { Ruleset.from_file(fixture).render == stripped_fixture }
        expect { Ruleset.from_s(File.read(fixture)).render == stripped_fixture }
      end
    end

    it "fails on invalid input" do
      expect { rescuing { Ruleset.from_s("Invalid!") }.is_a?(RuntimeError) }
    end
  end

  describe "Ruleset.from_command" do
    let(:fixture_text) { File.read(fixture("ghq.txt")) }
    let(:stripped_fixture) { fixture_text.lines.reject { |ln| ln =~ /^#/ }.join }

    it "executes external command and parses its output as ruleset" do
      Helpers.expects(:run_command).
        with('a', 'command', 'with', 'arguments').
        returns(fixture_text)
      rs = Ruleset.from_command('a', 'command', 'with', 'arguments')
      expect { rs.render == stripped_fixture }
      expect { rs.command == ['a', 'command', 'with', 'arguments'] }
    end

    it "has a convenience alias .from_iptables" do
      Helpers.expects(:run_command).with('iptables-save', '-c').returns(fixture_text)
      rs = Ruleset.from_iptables
      expect { rs.render == stripped_fixture }
      expect { rs.command == ['iptables-save', '-c'] }
      expect { rs.family == :inet }
    end

    it "has a convenience alias .from_ip6tables" do
      Helpers.expects(:run_command).with('ip6tables-save', '-c').returns(fixture_text)
      rs = Ruleset.from_ip6tables
      expect { rs.render == stripped_fixture }
      expect { rs.command == ['ip6tables-save', '-c'] }
      expect { rs.family == :inet6 }
    end
  end
end
