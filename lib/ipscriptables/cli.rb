require 'clamp'
require 'ipscriptables'

module IPScriptables
  class CLI < Clamp::Command
    option '--apply', :flag, 'Apply changes to iptables/ip6tables'
    option '--quiet', :flag, "Don't print diff"

    parameter "SCRIPT ...", "Ruby DSL spec(s) to evaluate", attribute_name: :scripts

    def execute
      runtime = IPScriptables::Runtime.new(apply: apply?, quiet: quiet?)
      scripts.each { |script| runtime.load_file(script) }
      runtime.execute!
    end
  end
end
