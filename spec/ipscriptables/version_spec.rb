# -*- coding: utf-8 -*-
require 'spec_helper'

# A smoke test spec to make sure tests actually work

module IPScriptables
  describe VERSION do
    it 'is equal to itself' do
      expect { VERSION == IPScriptables::VERSION }
    end
  end
end
