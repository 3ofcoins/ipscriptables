# -*- coding: utf-8 -*-

module IPScriptables
  class Table
    extend Forwardable
    def_delegators :@chains, :[]=, :[], :keys
    def_delegators :to_ary, :each, :empty?
    def_delegators :ruleset, :opts
    include Enumerable

    attr_reader :name, :ruleset
    def initialize(name, ruleset, &block)
      @name = name.to_sym
      @chains = Hashie::Mash.new
      @ruleset = ruleset

      create_builtin_chains unless ruleset.opts[:skip_builtin_chains]

      Docile.dsl_eval(self, &block) if block_given?
    end

    def original
      ruleset.original[name] if ruleset.original
    end

    BUILTIN_CHAINS = {
      filter:   [:INPUT, :FORWARD, :OUTPUT],
      nat:      [:PREROUTING, :INPUT, :OUTPUT, :POSTROUTING],
      mangle:   [:PREROUTING, :INPUT, :OUTPUT, :FORWARD, :POSTROUTING],
      raw:      [:PREROUTING, :OUTPUT],
      security: [:INPUT, :OUTPUT, :FORWARD]
    }

    def create_builtin_chains
      if BUILTIN_CHAINS.key? @name
        BUILTIN_CHAINS[@name].each do |builtin|
          chain builtin, :ACCEPT
        end
      else
        warn "Unrecognized table #{@name}, not creating builtin chains"
      end
    end

    def inherit(*names, &block) # rubocop:disable MethodLength
      fail 'Need original to inherit' unless ruleset.original
      original_table = ruleset.original[name]
      names = original_table.keys if names.empty?
      names.each do |name|
        original_chain = original_table[name]
        original_rules = original_chain.rules
        original_rules = original_rules.select(&block) if block_given?
        chain name, original_chain.policy, original_chain.counters do
          rules.concat(original_rules)
        end
      end
    end

    def to_ary
      @chains.values
    end

    def chain(name, *args, &block)
      if @chains.key?(name)
        @chains[name].alter(*args, &block)
      else
        @chains[name] = Chain.new(name, self, *args, &block)
      end
    end

    def render
      ["*#{name}",
       map(&:render_header).join("\n"),
       map(&:render_rules).compact.join("\n"),
       'COMMIT'].reject { |piece| piece == '' }.join("\n")
    end
  end
end
