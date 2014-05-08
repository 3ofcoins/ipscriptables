# -*- coding: utf-8 -*-
require 'spec_helper'

module IPScriptables
  describe 'Helpers.run_command' do
    def mock_status(success = true)
      rv = mock('Process::Status')
      rv.expects(:success?).at_least(0).returns(success)
      rv
    end

    it 'runs external command and returns its stdout' do
      Helpers.expects('systemu').with(%w(echo foo))
        .returns([mock_status, "foo\n", ''])
      expect { Helpers.run_command('echo', 'foo') == "foo\n" }
    end

    it 'raises RuntimError on failure status' do
      Helpers.expects('systemu').with(%w(false))
        .returns([mock_status(false), '', ''])
      expect { rescuing { Helpers.run_command('false') }.is_a?(RuntimeError) }
    end

    it 'prints command\'s stderr on stderr' do
      Helpers.expects('systemu').with(%w(cmd))
        .returns([mock_status, "bar\n", "foo\n"])
      out, err = capture_io { @res = Helpers.run_command('cmd') }
      expect { out == '' }
      expect { err == "cmd: foo\n" }
      expect { @res == "bar\n" }
    end

    it 'prints stdout on stderr in case of failure' do
      Helpers.expects('systemu').with(%w(cmd))
        .returns([mock_status(false), "foo\n", ''])
      out, err = capture_io do
        @rescued = rescuing { Helpers.run_command('cmd') }
      end
      expect { out == '' }
      expect { err == "cmd: foo\n" }
      expect { @rescued.is_a?(RuntimeError) }
    end
  end

  describe 'Helpers.ohai' do
    before { fauxhai! }

    it 'returns a configured instance of Ohai' do
      expect { Helpers.ohai['hostname'] == 'Fauxhai' }
    end

    it 'caches the ohai instance for better performance' do
      ohai1 = Helpers.ohai
      ohai2 = Helpers.ohai
      expect { ohai1.object_id == ohai2.object_id }
    end
  end
end
