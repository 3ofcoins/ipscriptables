actions :apply

default_action :apply

attr_accessor :block

def rules(&block)
  @block = block
end

def initialize(*)
  super
  run_context.include_recipe 'ipscriptables::load'
end
