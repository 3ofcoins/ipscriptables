# -*- coding: utf-8 -*-
require 'shellwords'

module IPScriptables
  class Rule
    OPTION_SYNONYMS = Hashie::Mash[
      :p => :protocol,
      :s => :source,
      :d => :destination,
      :j => :jump,
      :g => :goto,
      :i => :in_interface,
      :o => :out_interface,
      :f => :fragment,
      :m => :match,
      :sport => :source_port,
      :dport => :destination_port,
      :sports => :source_ports,
      :dports => :destination_ports
    ].freeze

    extend Forwardable
    attr_reader :chain, :rule, :counters
    def_delegators :chain, :opts

    def initialize(chain, rule, counters = nil) # rubocop:disable MethodLength
      @chain, @rule, @counters = chain, rule, counters
      @parsed = Hashie::Mash.new

      @counters ||= original.counters if original
      @counters ||= [0, 0] if opts[:counters]

      key = nil
      Shellwords.shellsplit(rule).each do |word|
        case word
        when /^-+(.*)$/
          self[key] = true if key
          key = Regexp.last_match[1].gsub('-', '_')
        else
          self[key] = word
          key = nil
        end
      end
    end

    def original
      chain.original.find { |rule| rule == self } if chain.original
    end

    def ==(other)
      other = other.rule if other.respond_to?(:rule)
      rule == other
    end

    def [](k)
      k = k.to_s.sub(/^-+/, '').gsub('-', '_')
      @parsed[OPTION_SYNONYMS.fetch(k, k)]
    end

    def proto
      self[:protocol]
    end

    def match
      Array(self[:m])
    end

    def target
      self[:jump]
    end

    def =~(other)
      rule =~ other
    end

    def render
      "#{render_counters}-A #{chain.name} #{rule}"
    end

    def render_counters
      "[#{counters.join(':')}] " if counters
    end

    private

    def []=(k, v)
      k = OPTION_SYNONYMS.fetch(k, k)
      if @parsed.key?(k)
        @parsed[k] = Array(@parsed[k]) << v
      else
        @parsed[k] = v
      end
    end
  end
end
