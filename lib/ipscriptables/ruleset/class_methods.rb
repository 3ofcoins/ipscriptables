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
        table = nil
        io.each_line do |ln|
          ln.strip!
          case ln
          when /^#/
            # comment, skip it
          when /^\*(.*)/
            fail RuntimeError unless table.nil?
            table = rs.table($1)
          when /^:(\w+) (\w+|-) \[(\d+):(\d+)\]$/
            table.chain $1, $2, [$3.to_i, $4.to_i]
          when /^(\[(\d+):(\d+)\] )?-A (\w+) (.*)/
            ch = table[$4]
            rule = $5
            counters = [$2.to_i, $3.to_i] if $1
            ch.rule(Rule.new(ch, rule, counters))
          when /^COMMIT$/
            fail 'COMMIT without table' if table.nil?
            table = nil
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

      def from_system(opts = {})
        opts[:family] ||= :inet
        case opts[:family]
        when :inet  then from_command 'iptables-save',  '-c', opts
        when :inet6 then from_command 'ip6tables-save', '-c', opts
        else fail NotImplementedError, "Unknonwn family #{opts[:family]}"
        end
      end

      def from_iptables(opts = {})
        from_system(opts.merge(family: :inet))
      end

      def from_ip6tables(opts = {})
        from_system(opts.merge(family: :inet6))
      end
    end
  end
end
