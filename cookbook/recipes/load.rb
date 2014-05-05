_version = node['ipscriptables']['gem_version']

chef_gem 'ipscriptables' do
  version _version if _version && _version != 'latest'
  action :upgrade if _version == 'latest'
end
