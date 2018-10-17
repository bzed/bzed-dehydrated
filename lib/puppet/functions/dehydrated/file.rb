# Returns the contents of a file - or nil
# if the file does not exist. based on file.rb from puppet.

Puppet::Functions.create_function(:'dehydrated::file') do
  dispatch :getfile do
    required_param 'String', :files
    optional_repeated_param 'String', :more_files
  end

  def getfile(files, *more_files)
    files = [files] + more_files
    files.each do |file|
      unless Puppet::Util.absolute_path?(file)
        raise(Puppet::ParseError, 'Files must be fully qualified')
      end
      if FileTest.exists?(file)
        File.read(file)
        break
      end
    end
    nil
  end
end
