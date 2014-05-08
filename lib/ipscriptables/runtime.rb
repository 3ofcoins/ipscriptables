# -*- coding: utf-8 -*-
# rubocop:disable BlockNesting

require 'English'
require 'logger'

module IPScriptables
  class Runtime
    DEFAULT_OPTS = { counters: true }
    attr_reader :log, :opts

    def initialize(opts = {}, logger = nil)
      @opts = DEFAULT_OPTS.merge(opts)
      @log = logger || Logger.new($stderr)
      @evaluating = 0
      @rulesets = {}
    end

    def ruleset(family)
      family = family.to_sym
      @rulesets[family] ||=
        IPScriptables::Ruleset.from_system(family: family).bud(opts)
    end

    def family(*families, &block)
      families.each do |family|
        begin
          @evaluating += 1
          ruleset(family).dsl_eval(&block)
        ensure
          @evaluating -= 1
        end
      end
    end

    def iptables(&block)
      family(:inet, &block)
    end

    def ip6tables(&block)
      family(:inet6, &block)
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

    def execute!  # rubocop:disable CyclomaticComplexity, MethodLength
      if @evaluating != 0
        fail "I can't let you do that (DSL eval depth #{@evaluating})"
      end

      ok = true
      @rulesets.sort.each do |family, ruleset|
        if !opts.fetch(family, true)
          log.info "Skipping #{family} as requested"
        else
          diff = ruleset.diff
          if diff.to_s.empty?
            log.info "No changes for #{family}, moving along."
          else
            log.info "Changes found for #{family}"
            format = opts.fetch(:color, $stdout.tty?) ? :color : :text
            puts diff.to_s(format) unless opts[:quiet]
            if opts[:apply]
              log.info "Restoring #{family}"
              begin
                ruleset.restore!
              rescue => e
                log.error "Failure restoring #{family}: #{e}"
                ok = false
                return ok if opts[:fail_fast]
              end
            else
              log.info "Would restore #{family}"
            end
          end
        end
      end

      log.warn 'There were errors' unless ok

      ok
    end
  end
end
