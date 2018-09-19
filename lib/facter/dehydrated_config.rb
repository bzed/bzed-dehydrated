require 'facter'
require 'json'

Facter.add(:dehydrated_config) do
    setcode do
        puppet_vardir = Facter.value(:puppet_vardir)
        configfile = "#{puppet_vardir}/config.json"

        if File.exist?(configfile) then
            JSON.parse(File.read(configfile))
        else
            nil
        end
    end
end
