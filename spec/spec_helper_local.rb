RSpec.configure do |c|
  c.enable_pathname_stubbing = true
end
WINDOWS = defined?(RSpec::Support) ? RSpec::Support::OS.windows? : !!File::ALT_SEPARATOR

