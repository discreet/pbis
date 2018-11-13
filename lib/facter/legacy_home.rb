Facter.add('legacy_home') do
  setcode do
    File.exists?('/home/local')
  end
end
