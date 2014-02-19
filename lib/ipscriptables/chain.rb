module IPScriptables
  class Chain
    extend Forwardable
    include Enumerable
    attr_reader :name, :table, :rules, :counters
    attr_accessor :policy
    def_delegators :rules, :each, :clear, :<<, :empty?
    def_delegators :table, :ruleset

    def initialize(name, table, policy='-', counters=[0,0], &block)
      @name = name
      @table = table
      @policy = policy
      @counters = counters
      @rules = []
      Docile.dsl_eval(self, &block) if block_given?
    end

    def alter(policy=nil, counters=nil, &block)
      @policy = policy unless policy.nil?
      @counters = counters unless counters.nil?
      Docile.dsl_eval(self, &block) if block_given?
    end

    def render_rule(r)
      r.to_s                    # FIXME: Rule type
    end

    def rule(r)
      @rules << render_rule(r)
    end

    def render_header
      ":#{name} #{policy} [#{counters.join(':')}]"
    end

    def render_rules
      rules.map { |rule| "-A #{name} #{rule}" }.join("\n") unless rules.empty?
    end
  end
end
