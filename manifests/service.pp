# Manage the IPTables and IP6Tables services
#
# @param enable
#   Enable IPTables
#
#   * If set to ``false`` with **disable** IPTables completely
#   * If set to ``ignore`` will stop managing IPTables
#
# @param ipv6
#   Also manage IP6Tables
#
class iptables::service (
  $enable = pick(getvar('::iptables::enable'),true),
  $ipv6   = pick(getvar('::iptables::ipv6'),true)
){
  if $enable != 'ignore' {
    if $enable {
      $_ensure = 'running'
    }
    else {
      $_ensure = 'stopped'
    }

    case $facts['os']['name'] {
      'RedHat','CentOS': {
        $_confdir = '/etc/sysconfig'
        $_provider = 'redhat'
      }
      'Debian','Ubuntu': {
        $_confdir = '/etc/default'
        $_provider = 'debian'
      }
      default: {
        fail("${::operatingsystem} is not yet supported by ${module_name}")
      }
    }

    service { 'iptables':
      ensure     => $_ensure,
      enable     => $enable,
      hasrestart => false,
      restart    => "/sbin/iptables-restore ${_confdir}/iptables || ( /sbin/iptables-restore ${_confdir}/iptables.bak && exit 3 )",
      hasstatus  => true,
      provider   => $_provider
    }

    service { 'iptables-retry':
      enable   => $enable,
      provider => $_provider
    }

    if $ipv6 and $facts['ipv6_enabled'] {
      service { 'ip6tables':
        ensure     => $_ensure,
        enable     => $enable,
        hasrestart => false,
        restart    => "/sbin/ip6tables-restore ${_confdir}/ip6tables || ( /sbin/ip6tables-restore ${_confdir}/ip6tables.bak && exit 3 )",
        hasstatus  => true,
        require    => File['/etc/init.d/ip6tables'],
        provider   => $_provider
      }

      service { 'ip6tables-retry':
        enable   => true,
        require  => File['/etc/init.d/ip6tables-retry'],
        provider => $_provider
      }
    }

    # firewalld must be disabled on EL7+
    case $::operatingsystem {
      'RedHat','CentOS': {
        if $::operatingsystemmajrelease > '6' {
          service{ 'firewalld':
            ensure => 'stopped',
            enable => false,
            before => Service['iptables']
          }
        }
      }
      'Debian','Ubuntu': {
      }
      default: {
        fail("${::operatingsystem} is not yet supported by ${module_name}")
      }
    }
  }
}
