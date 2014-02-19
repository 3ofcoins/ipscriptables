module IPScriptables
  class Ruleset
    def pretty_print(q)
      q.object_address_group(self) do
        q.group(2) do
          q.breakable
          q.seplist(self, ->{ q.breakable } ) {|v| q.pp v }
        end
      end
    end
  end

  class Table
    def pretty_print(q)
      q.group(2, "*#{name} {", "}") do
        unless @chains.empty?
          q.breakable
          q.seplist(self, ->{ q.breakable }) {|v| q.pp v }
        end
      end
    end
  end

  class Chain
    def pretty_print(q)
      q.group(2, "#{render_header} {", "}") do
        unless rules.empty?
          q.breakable
          q.seplist(rules, ->{ q.breakable " ; " } ) { |v| q.text v }
        end
      end
    end
  end
end
