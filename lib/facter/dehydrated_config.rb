require 'facter'
require 'json'

Facter.add(:dehydrated_config) do
  setcode do
    puppet_vardir = Facter.value(:puppet_vardir)
    configfile = File.join("#{puppet_vardir}", 'config.json')

    if File.exist?(configfile) then
      JSON.parse(File.read(configfile))
    else
      nil
    end
  end
end

Facter.add(:dehydrated_domains) do
  setcode do
    puppet_vardir = Facter.value(:puppet_vardir)
    domainsfile = File.join("#{puppet_vardir}", 'domains.txt')

    if File.exist?(domainsfile) then
      domains = File.read(domainsfile)
      domains_array = domains.split('\n')
      domains_array.reject { |e| e.to_s.empty? }
    else
      nil
    end
  end
end
