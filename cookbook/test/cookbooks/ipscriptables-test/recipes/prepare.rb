# -*- coding: utf-8 -*-

chef_gem 'ipscriptables' do
  source Dir['/tmp/kitchen/data/ipscriptables-*.gem'].sort.last
end
