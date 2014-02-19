require 'clamp'
require 'ipscriptables'

module IPScriptables
  class CLI < Clamp::Command
    class ScriptContext
      def initialize(file, &block)
        @callback = block
        instance_eval(File.read(file), file)
      end

      def iptables(&block)
        @callback.call(:iptables,  IPScriptables::Ruleset.from_iptables.bud( counters: true, &block))
      end

      def ip6tables(&block)
        @callback.call(:ip6tables, IPScriptables::Ruleset.from_ip6tables.bud(counters: true, &block))
      end
    end

    option '--apply', :flag, 'Apply changes to iptables/ip6tables'
    option '--quiet', :flag, "Don't print diff"

    parameter "SCRIPT", "Ruby DSL spec to evaluate", attribute_name: :script

    attr_reader :rulesets
    def handle_context_callback(name, ruleset)
      rulesets[name] = ruleset
    end

    def execute
      @rulesets = Hashie::Mash.new
      ScriptContext.new(script, &method(:handle_context_callback))
      rulesets.each do |name, ruleset|
        diff = ruleset.diff
        if diff.to_s.empty?
          puts "No changes in #{name}"
        else
          puts "Changes found in #{name}"
          puts(diff.to_s($stdout.tty? ? :color : :text)) unless apply? && quiet?
          if apply?
            puts "Running #{name}-restore -c ..."
            IO.popen(["#{name}-restore", "-c"], 'w') do |restore|
              restore.write(ruleset.render)
            end
            raise RuntimeError unless $?.success?
          else
            puts "Dry run, not applying changes\n"
          end
        end
      end
    end
  end
end
