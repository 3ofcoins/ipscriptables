# -*- coding: utf-8 -*-

require 'diffy'

require 'ipscriptables/helpers'
require 'ipscriptables/ruleset/class_methods'

module IPScriptables
  class Ruleset
    include Helpers

    attr_reader :opts
    extend Forwardable
    include Enumerable
    def_delegators :@tables, :[]=, :[]
    def_delegators :to_ary, :each
    def_delegators :opts, :original

    def initialize(opts = {}, &block)
      @tables = Hashie::Mash.new
      @opts = Hashie::Mash[opts]
      dsl_eval(&block) if block_given?
    end

    def dsl_eval(&block)
      Docile.dsl_eval(self, &block)
    end

    def load_file(path)
      dsl_eval { instance_eval(File.read(path), path) }
    end

    def respond_to?(meth)
      super || @opts.respond_to?(meth)
    end

    def method_missing(meth, *args, &block)
      if @opts.respond_to?(meth)
        @opts.send(meth, *args, &block)
      else
        super
      end
    end

    def bud(opts = {}, &block)
      child = self.class.new(opts.merge(
          skip_builtin_chains: true, original: self))
      each do |table|
        child_table = child.table(table.name)
        table.each do |chain|
          child_table.chain chain.name, chain.policy, chain.counters
        end
      end
      Docile.dsl_eval(child, &block) if block_given?
      child
    end

    def to_ary
      @tables.values
    end

    def table(name, &block)
      if @tables.key?(name)
        Docile.dsl_eval(@tables[name], &block)
      else
        self[name] = Table.new(name, self, &block)
      end
    end

    def inherit(table, *names, &block)
      self[table].inherit(*names, &block)
    end

    def render
      map(&:render).join("\n") << "\n"
    end

    def diff(from = nil)
      Diffy::Diff.new((from || original).render, render)
    end
  end
end
