# -*- coding: utf-8 -*-

module IPScriptables
  class Ruleset
    def inspect
      "#<#{self.class} [#{map(&:inspect).join(', ')}]>"
    end

    def pretty_print(q)
      q.object_address_group(self) do
        q.group(2) do
          q.breakable
          q.seplist(self, -> { q.breakable }) { |v| q.pp v }
        end
      end
    end
  end

  class Table
    def inspect
      "#<#{self.class} #{name} [#{map(&:inspect).join(', ')}]>"
    end

    def pretty_print(q)
      q.group(2, "*#{name} {", '}') do
        unless @chains.empty?
          q.breakable
          q.seplist(self, -> { q.breakable }) { |v| q.pp v }
        end
      end
    end
  end

  class Chain
    def inspect
      "#<#{self.class} #{name} [#{map(&:inspect).join(', ')}]>"
    end

    def pretty_print(q)
      q.group(2, "#{render_header} {", '}') do
        unless rules.empty?
          q.breakable
          q.seplist(rules, -> { q.breakable ' ; ' }) { |v| q.pp(v) }
        end
      end
    end
  end

  class Rule
    def inspect
      "#<#{self.class} #{render_counters}#{rule}>"
    end

    def pretty_print(q)
      q.text("#{render_counters}#{rule}")
    end
  end
end
