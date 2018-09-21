# Returns the contents of a file - or nil
# if no given file exists.
# Based on file.rb from puppet.
module Puppet::Parser::Functions
  # rubocop:disable Style/HashSyntax
  newfunction(:file_or_nil, :type => :rvalue, :doc => <<-DOC
    Return the contents of a file.  Multiple files
    can be passed, and the first file that exists will be read in.
    Return nil if none of the given file exists.
    Filenames must be absolute paths.
              DOC
               # rubocop:enable Style/HashSyntax
             ) do |args|
               ret = nil
               args.each do |file|
                 unless Puppet::Util.absolute_path?(file)
                   raise(Puppet::ParseError, 'Files must be fully qualified')
                 end
                 if FileTest.exists?(file)
                   ret = File.read(file)
                   break
                 end
               end
               ret
             end
end
