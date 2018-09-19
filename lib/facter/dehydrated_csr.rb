require 'facter'

Facter.add(:dehydrated_csrs) do
  setcode do
    dehydrated_config = Facter.value(:dehydrated_config)
    dehydrated_domains = Facter.value(:dehydrated_domains)
    if dehydrated_config and dehydrated_domains then
      csr_dir = dehydrated_config["csr_dir"]
      ret = Hash.new
      dehydrated_domains.each do |domain|
        ret[domain] = File.read(File.join(csr_dir, "#{domain}.csr"))
      end
      ret
    else
      nil
    end
  end
end


