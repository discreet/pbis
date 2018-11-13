# installs pbis in order to join AD domains
class pbis::install (
  $version = undef,
) {

  if !defined(Package['pbis-open']) and !defined(Package['pbis-open-upgrade']) {
    if $repos::installrepo {
      yumrepo { 'pbiso':
        descr    => "PBISO for ${::architecture}",
        baseurl  => "https://repo.pbis.beyondtrust.com/yum/pbiso/${::architecture}",
        enabled  => '1',
        gpgcheck => '1',
        gpgkey   => "https://repo.pbis.beyondtrust.com/yum/RPM-GPG-KEY-pbis",
      } ->

      package { 'pbis-open-upgrade':
        ensure => $version,
        before => Service['lwsmd'],
      }

      package { 'pbis-open':
        ensure  => $version,
        require => Package['pbis-open-upgrade'],
        before  => Service['lwsmd'],
      }
    }
  }

  service { 'lwsmd':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }
}
