# frozen_string_literal: true

# Returns the contents of a file - or nil
# if the file does not exist. based on file.rb from puppet.

require 'base64'

Puppet::Functions.create_function(:'dehydrated::file') do
  # @param files File to check
  # @param more_files optional other files to check
  dispatch :getfile do
    required_param 'String', :files
    optional_repeated_param 'String', :more_files
  end

  def getfile(files, *more_files)
    ret = nil
    files = [files] + more_files
    files.each do |file|
      raise(Puppet::ParseError, 'Files must be fully qualified') unless Puppet::Util.absolute_path?(file)
      next unless File.exist?(file)

      ret = File.read(file)
    end
    ret
  end
end
