require 'ohai'
require 'systemu'

module IPScriptables
  module Helpers
    extend Forwardable
    def_delegators IPScriptables::Helpers, :ohai, :run_command

    class << self
      def run_command(*argv)
        status, stdout, stderr = systemu(argv)
        unless status.success?
          $stderr.puts stdout.gsub(/^/, "#{argv.first}: ") unless stdout.empty?
          raise RuntimeError, stderr
        end
        $stderr.puts stderr.gsub(/^/, "#{argv.first}: ") unless stderr.empty?
        stdout
      end

      def ohai
        @ohai ||= setup_ohai
      end

      private

      def setup_ohai
        require 'ohai'
        ohai = Ohai::System.new
        %w[os platform kernel hostname network ip_scopes network_listeners cloud].each do |plugin|
          ohai.require_plugin plugin
        end
        ohai
      end
    end
  end
end
