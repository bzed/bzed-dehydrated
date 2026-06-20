# frozen_string_literal: true

# Managed by modulesync - DO NOT EDIT
# https://voxpupuli.org/docs/updating-files-managed-with-modulesync/

# puppetlabs_spec_helper will set up coverage if the env variable is set.
# We want to do this if lib exists and it hasn't been explicitly set.
ENV['COVERAGE'] ||= 'yes' if Dir.exist?(File.expand_path('../lib', __dir__))

require 'voxpupuli/test/spec_helper'

RSpec.configure do |c|
  c.facterdb_string_keys = false
end

module RspecPuppetFacts
  class << self
    alias_method :original_on_supported_os, :on_supported_os
    def on_supported_os(*args)
      stringify = lambda do |v|
        case v
        when Hash
          v.map { |k, val| [k.to_s, stringify.call(val)] }.to_h
        when Array
          v.map { |val| stringify.call(val) }
        else
          v
        end
      end

      original_on_supported_os(*args).map do |os, facts|
        stringified = stringify.call(facts)
        symbolized_top = stringified.map { |k, v| [k.to_sym, v] }.to_h
        [os, symbolized_top]
      end.to_h
    end
  end
end

add_mocked_facts!

if File.exist?(File.join(__dir__, 'default_module_facts.yml'))
  facts = YAML.safe_load(File.read(File.join(__dir__, 'default_module_facts.yml')))
  facts&.each do |name, value|
    add_custom_fact name.to_sym, value
  end
end
Dir['./spec/support/spec/**/*.rb'].sort.each { |f| require f }
