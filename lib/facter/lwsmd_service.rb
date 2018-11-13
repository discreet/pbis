Facter.add('lwsmd_service') do
  setcode do
    File.exists?('/usr/lib/systemd/system/lwsmd.service')
  end
end
