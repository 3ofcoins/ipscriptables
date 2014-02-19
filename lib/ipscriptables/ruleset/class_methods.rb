module IPScriptables
  class Ruleset
    include Helpers

    class << self
      def from_file(path, opts={})
        f = File.open(path)
        from_io(f, opts)
      ensure
        f.close if f
      end

      def from_io(io, opts={})
        rs = new(opts.merge(skip_builtin_chains: true))
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
            raise RuntimeError, "Cannot parse iptables-save line: #{ln}"
          end
        end
        rs
      end
      alias_method :from_s, :from_io # string also has `#each_line` method

      def from_command(*args)
        opts = args.last.is_a?(Hash) ? args.pop : {}
        from_s(Helpers.run_command(*args), opts.merge(command: args))
      end

      def from_iptables(opts={})
        # FIXME: -c
        from_command('iptables-save', opts.merge(family: :inet))
      end

      def from_ip6tables(opts={})
        # FIXME: -c
        from_command('ip6tables-save', opts.merge(family: :inet6))
      end
    end
  end
end
