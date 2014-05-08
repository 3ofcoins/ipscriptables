# -*- coding: utf-8 -*-

module IPScriptables
  class ChefHandler < Chef::Handler
    def report
      runtime.execute! if runtime
    end

    private

    def runtime
      node.run_state['ipscriptables_runtime']
    end
  end

  module ChefRecipeDSL
    def ipscriptables(name = nil, &block)
      name ||= "#{cookbook_name}::#{recipe_name}::#{_ipscriptables_counter}"
      ipscriptables_rules(name) { rules(&block) }
    end

    private

    def _ipscriptables_counter
      @ipscriptables_counter ||= 0
      @ipscriptables_counter += 1
    end
  end
end

class Chef
  class Recipe
    include IPScriptables::ChefRecipeDSL
  end
end
