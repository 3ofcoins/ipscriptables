# -*- coding: utf-8 -*-

module IPScriptables
  class Chain
    extend Forwardable
    include Enumerable
    attr_reader :name, :table, :rules, :counters
    attr_accessor :policy
    def_delegators :rules, :each, :clear, :<<, :empty?
    def_delegators :table, :ruleset, :opts

    def initialize(name, table, policy = '-', counters = [0, 0], &block)
      @name = name
      @table = table
      @policy = policy
      @counters = counters
      @rules = []
      @rule_stack = []
      Docile.dsl_eval(self, &block) if block_given?
    end

    def original
      table.original[name] if table.original
    end

    def alter(policy = nil, counters = nil, &block)
      @policy = policy unless policy.nil?
      @counters = counters unless counters.nil?
      Docile.dsl_eval(self, &block) if block_given?
    end

    def rule(term, *rest, &block) # rubocop:disable CyclomaticComplexity, MethodLength, LineLength
                                  # FIXME: ^^
      case term
      when Rule
        @rules << term         # we trust here that term.chain is self
      when Hash
        # Explode hash into [switch, value, switch, value, ...] sequence
        exploded = []
        term.each do |key, val|
          if key.is_a? Symbol
            key = key.to_s
            if key.length == 1
              exploded << "-#{key}"
            else
              exploded << "--#{key.gsub('_', '-')}"
            end
          else
            exploded << key.to_s
          end
          exploded << val
        end
        exploded.concat(rest)
        rule(*exploded, &block)
      when Enumerable
        term.each do |term1|
          rule(term1, *rest, &block)
        end
      else
        begin
          @rule_stack << term
          if !rest.empty?
            rule(*rest, &block)
          elsif block_given?
            yield
          else
            @rules << Rule.new(self, @rule_stack.map(&:to_s).join(' '))
          end
        ensure
          @rule_stack.pop
        end
      end
    end

    def render_header
      ":#{name} #{policy} [#{counters.join(':')}]"
    end

    def render_rules
      rules.map(&:render).join("\n") unless rules.empty?
    end
  end
end
