require 'spec_helper'

module IPScriptables
  describe "Helpers.run_command" do
    it "runs external command and returns its stdout" do
      slow_case
      expect { Helpers.run_command('echo', 'foo') == "foo\n" }
    end

    it "raises RuntimError on failure status" do
      slow_case
      expect { rescuing { Helpers.run_command('false') }.is_a?(RuntimeError) }
    end

    it "prints command's stderr on stderr" do
      slow_case
      out, err = capture_io { @res = Helpers.run_command('sh', '-c', 'echo foo >&2 ; echo bar') }
      expect { out == "" }
      expect { err == "sh: foo\n" }
      expect { @res == "bar\n" }
    end

    it "prints stdout on stderr in case of failure" do
      slow_case
      out, err = capture_io do
        @rescued = rescuing { Helpers.run_command('sh', '-c', 'echo foo ; exit 1') }
      end
      expect { out == "" }
      expect { err == "sh: foo\n" }
      expect { @rescued.is_a?(RuntimeError) }
    end
  end

  describe "Helpers.ohai" do
    it "returns a configured instance of Ohai" do
      slow_case
      require 'socket'
      expect { Helpers.ohai['hostname'] == Socket.gethostname }
    end

    it "caches the ohai instance for better performance" do
      slow_case
      expect { Helpers.ohai.object_id == Helpers.ohai.object_id }
    end
  end
end
