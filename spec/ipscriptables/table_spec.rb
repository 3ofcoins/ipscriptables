require 'spec_helper'

module IPScriptables
  describe Table do
    let(:ruleset) do
      rs = mock('ruleset')
      rs.expects(:opts).at_least_once.returns({})
      rs
    end

    it "creates built-in chains by default" do
      {
        filter:   [:INPUT, :FORWARD, :OUTPUT],
        nat:      [:PREROUTING, :INPUT, :OUTPUT, :POSTROUTING],
        mangle:   [:PREROUTING, :INPUT, :OUTPUT, :FORWARD, :POSTROUTING],
        raw:      [:PREROUTING, :OUTPUT],
        security: [:INPUT, :FORWARD, :OUTPUT],
      }.each do |table_name, expected_chains|
        expect { Set[*Table.new(table_name, ruleset).map(&:name)] == Set[*expected_chains] }
      end
    end

    it "warns about unrecognized table" do
      out, err = capture_io { @table = Table.new(:whatever, ruleset) }
      expect { out == "" }      # sanity
      expect { err =~ /Unrecognized table whatever/ }
      expect { @table.empty? }
    end
  end
end
