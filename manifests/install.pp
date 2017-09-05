# **NOTE: THIS IS A [PRIVATE](https://github.com/puppetlabs/puppetlabs-stdlib#assert_private) CLASS**
#
# Install the IPTables and IP6Tables components
#
# This also installs fallback startup scripts that come into play should the
# regular processes fail to start due to a race consition with DNS.
#
class iptables::install {
  assert_private()

  case $facts['os']['name'] {
    'RedHat','CentOS': {
      $_confdir = '/etc/sysconfig'
      $_filesubdir = ''
    }
    'Debian','Ubuntu': {
      $_confdir = '/etc/default'
      $_filesubdir = 'debian/'
    }
    default: {
      fail("${::operatingsystem} is not yet supported by ${module_name}")
    }
  }

  # IPV4-only stuff
  package { 'iptables': ensure => $::iptables::ensure }

  file { '/etc/init.d/iptables':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0744',
    content => file("${module_name}/${_filesubdir}iptables"),
    seltype => 'iptables_initrc_exec_t'
  }

  # --------------------------------------------------
  # Set the iptables startup script to fail safe.
  #
  file { '/etc/init.d/iptables-retry':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0744',
    content => file("${module_name}/${_filesubdir}iptables-retry"),
    seltype => 'iptables_initrc_exec_t'
  }

  file { "${_confdir}/iptables":
    owner => 'root',
    group => 'root',
    mode  => '0640'
  }

  Package['iptables'] -> File['/etc/init.d/iptables']
  Package['iptables'] -> File['/etc/init.d/iptables-retry']
  Package['iptables'] -> File["${_confdir}/iptables"]

  if $::iptables::ipv6 and $facts['ipv6_enabled'] {
    # IPV6-only stuff
    file { '/etc/init.d/ip6tables':
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => '0744',
      seltype => 'iptables_initrc_exec_t',
      content => file("${module_name}/${_filesubdir}ip6tables")
    }

    file { '/etc/init.d/ip6tables-retry':
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => '0744',
      seltype => 'iptables_initrc_exec_t',
      content => file("${module_name}/${_filesubdir}ip6tables-retry")
    }

    file { "${_confdir}/ip6tables":
      owner => 'root',
      group => 'root',
      mode  => '0640'
    }

    case $facts['os']['name'] {
      'RedHat','CentOS': {
        if $facts['os']['release']['major'] > '6' {
          Package['iptables'] -> File['/etc/init.d/ip6tables']
          Package['iptables'] -> File['/etc/init.d/ip6tables-retry']
          Package['iptables'] -> File["${_confdir}/ip6tables"]
        }
        else {
          package { 'iptables-ipv6': ensure => $::iptables::ensure }
          Package['iptables-ipv6'] -> File['/etc/init.d/ip6tables']
          Package['iptables-ipv6'] -> File['/etc/init.d/ip6tables-retry']
          Package['iptables-ipv6'] -> File["${_confdir}/ip6tables"]
        }
      }
      'Debian','Ubuntu': {
        Package['iptables'] -> File['/etc/init.d/ip6tables']
        Package['iptables'] -> File['/etc/init.d/ip6tables-retry']
        Package['iptables'] -> File["${_confdir}/ip6tables"]
      }
      default: {
        fail("${::operatingsystem} is not yet supported by ${module_name}")
      }
    }
  }
}
