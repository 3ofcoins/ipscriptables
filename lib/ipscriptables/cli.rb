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
        @callback.call(:iptables, IPScriptables::Ruleset.from_iptables.bud(&block))
      end

      def ip6tables(&block)
        @callback.call(:ip6tables, IPScriptables::Ruleset.from_iptables.bud(&block))
      end
    end

    option '--apply', 'Apply changes to iptables/ip6tables'

    parameter "SCRIPT", "Ruby DSL spec to evaluate", attribute_name: script
  end
end
