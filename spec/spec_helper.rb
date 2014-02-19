require 'rubygems'
require 'bundler/setup'

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/' unless ENV['SPEC_COVERAGE']
    add_filter '/lib/ipscriptables/pretty_print.rb'
  end
  SimpleCov.command_name 'spec'
end

require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/pride' if $stderr.tty?
require 'mocha/setup'
require 'wrong'

Wrong.config.alias_assert :expect, override: true
include Wrong

class Minitest::Spec
  include ::Wrong::Assert
  include ::Wrong::Helpers

  def slow_case
    skip if !ENV['CI'] && ENV['FASTER']
  end

  def self.fixture(*path)
    File.join(File.realpath(File.dirname(__FILE__)), "fixtures", *path)
  end

  def fixture(*path)
    # Why the hell can't I have module_function in a class, huh?
    self.class.fixture(*path)
  end

  def increment_assertion_count
    self.assertions += 1
  end

  def failure_class
    Minitest::Assertion
  end
end

require "ipscriptables"
