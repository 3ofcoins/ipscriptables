require 'hashie'
require 'systemu'

require "ipscriptables/version"

module IPScriptables
  def self.systemu!(cmd)
    status, stdout, stderr = systemu(*args)
    unless status.success?
      puts stdout unless stdout.empty?
      raise RuntimeError, stderr
    end
    stdout
  end

  class Ruleset
    class << self
      def from_file(path)
        f = File.open(path)
        from_io(f)
      ensure
        f.close
      end

      def from_io(io)
        rs = new(skip_builtin_chains: true)
        _table = nil
        io.each_line do |ln|
          ln.strip!
          case ln
          when /^#/
            # comment, skip it
          when /^\*(.*)/
            raise RuntimeError unless _table.nil?
            _table = rs.table($1)
          when /^:(\w+) (\w+|-) \[(\d+):(\d+)\]$/
            _table.chain($1, $2, [$3.to_i, $4.to_i])
          when /^-A (\w+) (.*)/
            _table[$1] << $2
          when /^COMMIT$/
            raise RuntimeError if _table.nil?
            _table = nil
          else
            raise RuntimeError, ln
          end
        end
        rs
      end
      alias_method :from_s, :from_io

      def from_command(command)
        from_s(IPScriptables.systemu!(command))
      end

      def from_iptables
        from_command('iptables-save -c')
      end

      def from_ip6tables
        from_command('ip6tables-save -c')
      end
    end

    extend Forwardable
    def_delegators :@tables, :[]=, :[]
    def_delegators :to_ary, :each, :map
    attr_reader :opts

    def initialize(opts={}, &block)
      @tables = Hashie::Mash.new
      @opts = Hashie::Mash[opts]
      instance_eval(&block) if block_given?
    end

    def to_ary
      @tables.values
    end

    def <<(table)
      self[table.name] = table
    end

    def table(name, &block)
      self[name] ||= Table.new(name, opts, &block)
    end

    def render
      map(&:render).join("\n") << "\n"
    end

    def pretty_print(q)
      q.object_address_group(self) do
        q.group(2) {
          q.breakable
          q.seplist(self, ->{ q.breakable } ) {|v| q.pp v }
        }
      end
    end
  end

  class Table
    extend Forwardable
    def_delegators :@chains, :[]=, :[]
    def_delegators :to_ary, :each, :map

    attr_reader :name, :opts
    def initialize(name, opts={}, &block)
      @name = name.to_sym
      @chains = Hashie::Mash.new
      @opts = opts

      create_builtin_chains unless opts[:skip_builtin_chains]

      instance_eval(&block) if block_given?
    end

    def create_builtin_chains
      # initalize builtin chains
      case @name
      when :filter
        chain :INPUT,       :ACCEPT
        chain :FORWARD,     :ACCEPT
        chain :OUTPUT,      :ACCEPT
      when :nat
        chain :PREROUTING,  :ACCEPT
        chain :INPUT,       :ACCEPT
        chain :OUTPUT,      :ACCEPT
        chain :POSTROUTING, :ACCEPT
      when :mangle
        chain :PREROUTING,  :ACCEPT
        chain :OUTPUT,      :ACCEPT
        chain :INPUT,       :ACCEPT
        chain :FORWARD,     :ACCEPT
        chain :POSTROUTING, :ACCEPT
      when :raw
        chain :PREROUTING,  :ACCEPT
        chain :OUTPUT,      :ACCEPT
      when :security
        chain :INPUT,       :ACCEPT
        chain :OUTPUT,      :ACCEPT
        chain :FORWARD,     :ACCEPT
      else
        warn "Unrecognized table #{@name}, not creating builtin chains"
      end
    end

    def to_ary
      @chains.values
    end

    def <<(chain)
      @chains[chain.name] = chain
    end

    def chain(name, *args, &block)
      if @chains.key?(name)
        @chains[name].alter(*args, &block)
      else
        @chains[name] = Chain.new(name, opts, *args, &block)
      end
    end

    def render
      [ "*#{name}",
        map(&:render_header).join("\n"),
        map(&:render_rules).compact.join("\n"),
        "COMMIT",
      ].reject { |piece| piece == "" }.join("\n")
    end

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
    attr_reader :name, :rules, :counters
    attr_accessor :policy
    def initialize(name, opts, policy='-', counters=[0,0], &block)
      @name = name
      @opts = opts
      @policy = policy
      @counters = counters
      @rules = []
      instance_eval(&block) if block_given?
    end

    def alter(policy=nil, counters=nil, &block)
      @policy = policy unless policy.nil?
      @counters = counters unless counters.nil?
      instance_eval(&block) if block_given?
    end

    def render_rule(r)
      case r
      when String then r
      when Hash then raise NotImplementedError
      when Iterable then r.map { |elt| render_rule(elt) }.join(' ')
      else raise ValueError
      end
    end

    def rule(r)
      @rules << render_rule(r)
    end

    def <<(rule)
      @rules << rule
    end

    def render_header
      ":#{name} #{policy} [#{counters.join(':')}]"
    end

    def render_rules
      rules.map { |rule| "-A #{name} #{rule}" }.join("\n") unless rules.empty?
    end

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
