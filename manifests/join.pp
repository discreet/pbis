# == Define: pbis::join
#
# === Parameters
#
# [*username*]
#   The service account that is used to bind the hosts to the domain
#
# [*password*]
#   The password for the service account
#
# [*domain*]
#   The domain to bind the hosts to
#
# [*org_unit*]
#   The OU in Active Directory the computer object should live in
#   *optional
#
# [*group_access*]
#   A list of groups and/or users who require access to the host
#
# === Authors
#
# Christopher Pisano <cpisano86@gmail.com>
#
# === Copyright
#
# Copyright 2015
#
define pbis::join (

  $username     = 'puppetsvc',
  $version      = undef,
  $password     = undef,
  $domain       = undef,
  $org_unit     = undef,
  $group_access = undef,
) {

  if $::dmz != true {
    Exec {
      path => '/opt/pbis/bin',
    }

    if $org_unit {
      $command = "domainjoin-cli join --ou ${org_unit} ${domain} ${username} ${password}"
    }else {
      $command = "domainjoin-cli join ${domain} ${username} ${password}"
    }

    exec { "join-${name}":
      command   => $command,
      tries     => '2',
      try_sleep => '10',
      unless    => "lsa ad-get-machine account 2>/dev/null",
    } ->

    exec { "default-${domain}":
      command => 'config assumeDefaultDomain true',
      unless  => "config --details assumeDefaultDomain | /bin/grep 'Current Value:.*true'",
      returns => [0,5],
    } ->

    exec { "${::hostname}-homedir":
      command => 'config HomeDirTemplate %H/%U',
      unless  => "config --detail HomeDirTemplate | /bin/grep 'Current Value:.*%H/%U'",
      returns => [0,5],
    } ->

    exec { "${::hostname}-shell":
      command => 'config LoginShellTemplate /bin/bash',
      unless  => "config --details LoginShellTemplate | /bin/grep 'Current Value:.*/bin/bash'",
      returns => [0,5],
    } ->

    file { "${::hostname}-access":
      ensure  => file,
      path    => '/tmp/user_access',
      owner   => root,
      group   => root,
      mode    => '0444',
      content => join($group_access, ' '),
    } ->

    exec { "${::hostname}-members":
      command     => "config RequireMembershipOf ${group_access}",
      refreshonly => true,
      logoutput   => true,
      notify      => Exec["${name}-service"],
      subscribe   => File["${::hostname}-access"],
    } ->

    exec { "${name}-service":
      command     => 'lwsm refresh lsass',
      refreshonly => true,
    }
  }
}
