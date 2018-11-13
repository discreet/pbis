require 'facter'

Facter.add("pbis_version") do
  confine :osfamily => 'RedHat'
  setcode do
    if File.exists?("/opt/pbis")
      if File.executable?("/opt/pbis/bin/pbis-status")
        result = Facter::Util::Resolution.exec("/opt/pbis/bin/pbis-status | /bin/grep 'Compiled daemon version:'")
        if result
          version = result.sub(%r{\D+(\d*\.\d*\.\d*)},'\1')
          if version.empty? or version.nil?
            '0.unknown'
          else
            version
          end
        else
          "PBIS Output Error"
        end
      else
        "PBIS Executable Missing"
      end
    else
      "PBIS Not Installed"
    end
  end
end
