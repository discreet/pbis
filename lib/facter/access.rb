require 'facter'

Facter.add("user_access") do
  confine :osfamily => 'RedHat'
  setcode do
    if File.exists?("/opt/pbis")
      if File.executable?("/opt/pbis/bin/config")
        access = `/opt/pbis/bin/config --detail RequireMembershipOf | grep '"' | sed -e 's/^"//' -e 's/"$//'`
      else
        "PBIS Executable Missing"
      end
    else
      "PBIS Not Installed"
    end
  end
end
