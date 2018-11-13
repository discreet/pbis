# == Class: pbis
#
# This module manages the joining of a Linux server to an Active Directory
# domain. The PBIS module does four things; installs PBIS, joins a domain, sets
# the default domain and shell and configures user access.
#
# === Parameters
#
# Document parameters here.
#
# [*username*]
#   The service account that is used to bind the hosts to the domain
#
# [*password*]
#   The password for the service account
#
# [*package*]
#   The pbis-open rpm package to install
#
# [*version*]
#   The version of PBISO to install
#
# [*domain*]
#   The domain to bind the hosts to
#
# [*org_unit*]
#   The OU in Active Directory the computer object should live in
#
# [*group_access*]
#   A list of groups and/or users who require access to the host
#
# === Variables
#
# [*repos::installrepo*]
#   This variable must be set to "true" in either the ENC or Hiera data if you
#   wish for this Class to install the PBISO repository. If this variable is set
#   to "false" the server will be considered a "repository mirror" and PBISO
#   will not be installed and configured to point to a local mirror.
#
# === Examples
#
#  class { 'pbis':
#    domain => 'foo.com',
#  }
#
# === Authors
#
# Christopher Pisano <cpisano86@gmail.com.com>
#
# === Copyright
#
# Copyright 2015
#
class pbis (

  $username        = 'puppetsvc',
  $password        = '',
  $package         = 'pbis-open',
  $upgrade_package = 'pbis-open-upgrade',
  $version         = '',
  $domain          = '',
  $org_unit        = '',
  $group_access    = '',
) {

  if $::legacy_home == true {
    $homedir       = 'config HomeDirTemplate %H/local/%D/%U'
    $check_homedir = "config --detail HomeDirTemplate | /bin/grep 'Current Value:.*%H/local/%D/%U'"
  }else {
    $homedir       = 'config HomeDirTemplate %H/%U'
    $check_homedir = "config --detail HomeDirTemplate | /bin/grep 'Current Value:.*%H/%U'"
  }

  yumrepo { 'pbiso':
    descr    => "PBISO for ${::architecture}",
    baseurl  => "https://repo.pbis.beyondtrust.com/yum/pbiso/${::architecture}",
    enabled  => '1',
    gpgcheck => '1',
    gpgkey   => "https://repo.pbis.beyondtrust.com/yum/RPM-GPG-KEY-pbis",
  }

  package { $upgrade_package:
    ensure  => $version,
    require => Yumrepo['pbiso'],
  }

  package { $package:
    ensure  => $version,
    require => Package[$upgrade_package],
  }

  if $::lwsmd_service {
    file  {'/usr/lib/systemd/system/lwsmd.service' :
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
    }
  }

  service { 'lwsmd':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => [ "Package[${package}]",
                    "Package[${upgrade_package}]"
                  ],
  }

  if $org_unit {
    $command = "domainjoin-cli join --ou ${org_unit} ${domain} ${username} ${password}"
  }else {
    $command = "domainjoin-cli join ${domain} ${username} ${password}"
  }

  exec { 'pbisJoinDomain':
    path      => '/opt/pbis/bin',
    command   => $command,
    tries     => '2',
    try_sleep => '10',
    unless    => 'lsa ad-get-machine account 2>/dev/null',
    require   => Package[$package],
  }

  exec { 'pbisAssumeDefaultDomain':
    path    => '/opt/pbis/bin',
    command => 'config assumeDefaultDomain true',
    unless  => "config --details assumeDefaultDomain | /bin/grep 'Current Value:.*true'",
    returns => [0,5],
    require => Exec['pbisJoinDomain'],
  }

  exec { 'pbisHomeDirTemplate':
    path    => '/opt/pbis/bin',
    command => $homedir,
    unless  => $check_homedir,
    returns => [0,5],
    require => Exec['pbisJoinDomain'],
  }

  exec { 'pbisLoginShellTemplate':
    path    => '/opt/pbis/bin',
    command => 'config LoginShellTemplate /bin/bash',
    unless  => "config --details LoginShellTemplate | /bin/grep 'Current Value:.*/bin/bash'",
    returns => [0,5],
    require => Exec['pbisJoinDomain'],
  }

  file { 'user_access':
    ensure  => present,
    path    => '/tmp/user_access',
    owner   => root,
    group   => root,
    mode    => '0444',
    content => join($group_access, ' '),
    notify  => Exec['pbisRequireMembershipOf'],
    before  => Exec['pbisRequireMembershipOf'],
  }

  exec { 'pbisRequireMembershipOf':
    path        => '/opt/pbis/bin',
    command     => "config RequireMembershipOf ${group_access}",
    refreshonly => true,
    logoutput   => true,
    require     => Exec['pbisJoinDomain'],
    notify      => Exec['pbisRefreshLSASS'],
  }

  exec { 'pbisRefreshLSASS':
    path        => '/opt/pbis/bin',
    command     => 'lwsm refresh lsass',
    refreshonly => true,
    require     => Exec['pbisRequireMembershipOf'],
  }
}
