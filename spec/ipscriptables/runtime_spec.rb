# -*- coding: utf-8 -*-
# rubocop:disable LineLength
require 'spec_helper'

require 'stringio'

module IPScriptables
  describe Runtime do
    let(:fixture_text) { File.read(fixture('only-docker-c.txt')) }
    let(:fixture6_text) { File.read(fixture('ip6tables-empty.txt')) }
    let(:runtime) { Runtime.new }

    before do
      IO.expects(:popen).never  # just to be safe
      Helpers.expects(:run_command).with('ip6tables-save', '-c')
        .at_most_once
        .returns(fixture6_text)
      Helpers.expects(:run_command).with('iptables-save', '-c')
        .at_most_once
        .returns(fixture_text)
    end

    it 'does not run undefined rulesets' do
      out, err = capture_io { runtime.execute! }
      expect { out == '' }
      expect { err =~ /No iptables ruleset defined, moving along/ }
      expect { err =~ /No ip6tables ruleset defined, moving along/ }
    end

    it 'can load rulesets from file' do
      out, err = capture_io do
        runtime.load_file(fixture('runtime.rb'))
        runtime.execute!
      end

      expect { err =~ /No ip6tables ruleset defined, moving along/ }
      expect { err =~ /Loading configuration from #{fixture('runtime.rb')}/ }
      deny   { err =~ /Loading configuration from #{fixture('runtime2.rb')}/ }
      expect { out.lines.grep(/^\S/).length == 4 }
      expect { err =~ /Would run iptables-restore/ }
    end

    it 'can load multiple files & won\'t run if rules are unchanged' do
      out, err = capture_io do
        runtime.load_file(fixture('runtime.rb'))
        runtime.load_file(fixture('runtime2.rb'))
        runtime.execute!
      end

      expect { err =~ /No ip6tables ruleset defined, moving along/ }
      expect { err =~ /Loading configuration from #{fixture('runtime.rb')}/ }
      expect { err =~ /Loading configuration from #{fixture('runtime2.rb')}/ }
      expect { out.lines.grep(/^\S/).empty? }
      expect { err =~ /No changes for iptables, moving along./ }
    end

    it 'accepts blocks as well as files' do
      out, err = capture_io do
        runtime.load_file(fixture('runtime.rb'))
        runtime.dsl_eval do
          iptables do
            table :nat do
              chain :PREROUTING do
                rule '-m addrtype --dst-type LOCAL -j DOCKER'
              end
              chain :OUTPUT do
                rule '! -d 127.0.0.0/8 -m addrtype --dst-type LOCAL -j DOCKER'
              end
              chain :POSTROUTING do
                rule '-s 172.17.0.0/16 ! -d 172.17.0.0/16 -j MASQUERADE'
                rule '-s 10.0.3.0/24 ! -d 10.0.3.0/24 -j MASQUERADE'
              end
            end
          end
        end
        runtime.execute!
      end

      expect { err =~ /No ip6tables ruleset defined, moving along/ }
      expect { err =~ /Loading configuration from #{fixture('runtime.rb')}/ }
      expect { out.lines.grep(/^\S/).empty? }
      expect { err =~ /No changes for iptables, moving along./ }
    end

    it 'configures ipv6' do
      out, err = capture_io do
        runtime.dsl_eval do
          ip6tables do
            table :filter do
              chain :INPUT do
                rule :m => :tcp, :p => :tcp, :dport => 22, :j => :ACCEPT
              end
            end
          end
        end
        runtime.execute!
      end

      expect { err =~ /No iptables ruleset defined, moving along/ }
      expect { out =~ /^\+\[0:0\] -A INPUT -m tcp -p tcp --dport 22 -j ACCEPT$/ }
      expect { err =~ /Would run ip6tables-restore./ }
    end

    it 'doesn\'t allow triggering execution from within DSL' do
      expect do
        rescuing { runtime.dsl_eval { execute! } }.to_s =~
          /I can't let you do that/
      end
    end

    describe 'options' do
      before do
        $CHILD_STATUS.expects(:success?).at_least(0).returns(true)

        @out, @err = capture_io do
          runtime.load_file(fixture('runtime.rb'))
          runtime.dsl_eval do
            ip6tables do
              table :filter do
                chain :FORWARD, :DROP
                chain :INPUT, :DROP do
                  rule :m => :tcp, :p => :tcp, :dport => 22, :j => :ACCEPT
                end
              end
            end
          end
        end
      end

      it 'behaves normally without options' do
        out, _err = capture_io { runtime.execute! }
        expect { out.lines.grep(/^\S/).length == 9 }
        expect { @err =~ /Would run iptables-restore./ }
        expect { @err =~ /Would run ip6tables-restore./ }
      end

      it 'can be instructed to skip a ruleset' do
        runtime.opts[:ip6tables] = false
        out, _err = capture_io { runtime.execute! }
        expect { out.lines.grep(/^\S/).length == 4 }
        expect { @err =~ /Would run iptables-restore./ }
        expect { @err =~ /Skipping ip6tables as requested/ }
      end

      it 'applies rules only when specifically told' do
        runtime.opts[:apply] = true

        iptables_restore_io = mock('IO')
        iptables_restore_io.expects(:write).once.with <<EOF
*filter
:INPUT ACCEPT [211:14626]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [122:11280]
[1:2] -A FORWARD -o docker0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
[1:2] -A FORWARD -i docker0 ! -o docker0 -j ACCEPT
[1:2] -A FORWARD -i docker0 -o docker0 -j ACCEPT
COMMIT
*nat
:PREROUTING ACCEPT [5:1208]
:INPUT ACCEPT [5:1208]
:OUTPUT ACCEPT [42:3215]
:POSTROUTING ACCEPT [42:3215]
:DOCKER - [0:0]
COMMIT
EOF

        ip6tables_restore_io = mock('IO')
        ip6tables_restore_io.expects(:write).once.with <<EOF
*filter
:INPUT DROP [128:11760]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [75:12168]
[0:0] -A INPUT -m tcp -p tcp --dport 22 -j ACCEPT
COMMIT
EOF

        IO.expects(:popen).with(%w(iptables-restore -c), 'w').once.yields(iptables_restore_io)
        IO.expects(:popen).with(%w(ip6tables-restore -c), 'w').once.yields(ip6tables_restore_io)

        capture_io { @rv = runtime.execute! }
        expect { @err =~ /Running iptables-restore -c/ }
        expect { @err =~ /Running ip6tables-restore -c/ }
        deny   { @err =~ /There were errors/ }
        expect { @rv == true }
      end

      it 'logs error and proceeds, but returns false, when restore command fails' do
        runtime.opts[:apply] = true

        iptables_restore_io = mock('IO')
        iptables_restore_io.expects(:write).once
        ip6tables_restore_io = mock('IO')
        ip6tables_restore_io.expects(:write).once
        $CHILD_STATUS.expects(:success?)
          .once.returns(false).then.returns(true)

        IO.expects(:popen).with(%w(iptables-restore -c), 'w').once.yields(iptables_restore_io)
        IO.expects(:popen).with(%w(ip6tables-restore -c), 'w').once.yields(ip6tables_restore_io)

        out, _err = capture_io { @rv = runtime.execute! }
        expect { out.lines.grep(/^\S/).length == 9 }
        expect { @err =~ /Running iptables-restore -c/ }
        expect { @err =~ /Running ip6tables-restore -c/ }
        expect { @err =~ /ERROR.* Failure in iptables-restore/ }
        expect { @err =~ /There were errors/ }
        expect { @rv == false }
      end

      it 'does not output diff when quiet flag is specified' do
        runtime.opts[:quiet] = true

        out, _err = capture_io { @rv = runtime.execute! }
        expect { out == '' }
        expect { @err =~ /Would run iptables-restore -c/ }
        expect { @err =~ /Would run ip6tables-restore -c/ }
      end
    end
  end
end
