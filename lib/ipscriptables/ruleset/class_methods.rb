# -*- coding: utf-8 -*-

module IPScriptables
  class Ruleset
    include Helpers

    class << self
      def from_file(path, opts = {})
        f = File.open(path)
        from_io(f, opts)
      ensure
        f.close if f
      end

      def from_io(io, opts = {}) # rubocop:disable CyclomaticComplexity, MethodLength, LineLength
        rs = new(opts.merge(skip_builtin_chains: true))
        _table = nil
        io.each_line do |ln|
          ln.strip!
          case ln
          when /^#/
            # comment, skip it
          when /^\*(.*)/
            fail RuntimeError unless _table.nil?
            _table = rs.table(Regexp.last_match[1])
          when /^:(\w+) (\w+|-) \[(\d+):(\d+)\]$/
            _table.chain Regexp.last_match[1],
                         Regexp.last_match[2],
                         Regexp.last_match[3..4].map(&:to_i)
          when /^(\[(\d+):(\d+)\] )?-A (\w+) (.*)/
            ch = _table[Regexp.last_match[4]]
            rule = Regexp.last_match[5]
            counters = Regexp.last_match[2..3].map(&:to_i) if Regexp.last_match[1]
            ch.rule(Rule.new(ch, rule, counters))
          when /^COMMIT$/
            fail 'COMMIT without table' if _table.nil?
            _table = nil
          else
            fail "Cannot parse iptables-save line: #{ln}"
          end
        end
        rs
      end
      alias_method :from_s, :from_io # string also has `#each_line` method

      def from_command(*args)
        opts = args.last.is_a?(Hash) ? args.pop : {}
        from_s(Helpers.run_command(*args), opts.merge(command: args))
      end

      def from_iptables(opts = {})
        from_command('iptables-save', '-c', opts.merge(family: :inet))
      end

      def from_ip6tables(opts = {})
        from_command('ip6tables-save', '-c', opts.merge(family: :inet6))
      end
    end
  end
end
