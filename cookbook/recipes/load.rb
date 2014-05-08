# -*- coding: utf-8 -*-

gem_version = node['ipscriptables']['gem_version']

chef_gem 'ipscriptables' do
  version gem_version if gem_version && gem_version != 'latest'
  action :upgrade if gem_version == 'latest'
end
