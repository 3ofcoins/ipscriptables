# -*- coding: utf-8 -*-

def whyrun_supported?
  true
end

action :apply do
  converge_by('Evaluating rules') do
    runtime.dsl_eval(&new_resource.block)
  end
  new_resource.updated_by_last_action(true)
end

def runtime
  node.run_state['ipscriptables_runtime'] ||=
    begin
      require 'ipscriptables'
      Chef::Config.report_handlers << IPScriptables::ChefHandler.new
      IPScriptables::Runtime.new(apply: !whyrun_mode?)
    end
end
