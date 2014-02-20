require 'logger'

module IPScriptables
  class Runtime
    DEFAULT_OPTS = { counters: true }
    attr_reader :log, :opts

    def initialize(opts={}, logger=nil)
      @opts = DEFAULT_OPTS.merge(opts)
      @log = logger || Logger.new($stderr)
      @evaluating = 0
    end

    def iptables(&block)
      @evaluating += 1
      ( @iptables ||= IPScriptables::Ruleset.from_iptables.bud(opts) ).
        dsl_eval(&block)
    ensure
      @evaluating -= 1
    end

    def ip6tables(&block)
      @evaluating += 1
      ( @ip6tables ||= IPScriptables::Ruleset.from_ip6tables.bud(opts) ).
        dsl_eval(&block)
    ensure
      @evaluating -= 1
    end

    def load_file(path)
      @evaluating += 1
      log.info "Loading configuration from #{path}"
      instance_eval(File.read(path), path)
    ensure
      @evaluating -= 1
    end

    def dsl_eval(&block)
      @evaluating += 1
      instance_eval(&block)
    ensure
      @evaluating -= 1
    end

    def execute!
      if @evaluating != 0
        raise RuntimeError, "I can't let you do that (DSL eval depth #{@evaluating})"
      end

      ok = true

      { iptables: @iptables, ip6tables: @ip6tables }.each do |name, ruleset|
        if ruleset.nil?
          log.debug "No #{name} ruleset defined, moving along"
        elsif ! opts.fetch(name, true)
          log.info "Skipping #{name} as requested"
        else
          diff = ruleset.diff
          if diff.to_s.empty?
            log.info "No changes for #{name}, moving along."
          else
            log.info "Changes found for #{name}"
            format = opts.fetch(:color, $stdout.tty?) ? :color : :text
            puts diff.to_s(format) unless opts[:quiet]
            if opts[:apply]
              log.info "Running #{name}-restore -c"
              IO.popen(["#{name}-restore", "-c"], 'w') do |restore|
                restore.write(ruleset.render)
              end
              if $?.success?
                log.debug "Successfully finished #{name}-restore"
              else
                log.error "Failure in #{name}-restore: #{$?}"
                ok = false
                return ok if opts[:fail_fast]
              end
            else
              log.info "Would run #{name}-restore -c"
            end
          end
        end
      end

      log.warn "There were errors" unless ok

      return ok
    end
  end
end
