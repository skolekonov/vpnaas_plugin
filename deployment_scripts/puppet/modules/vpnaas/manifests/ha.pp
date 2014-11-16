class vpnaas::ha {

    include vpnaas::params

#    exec {'waiting-for-vpn-agent':
#      tries     => 90,
#      try_sleep => 60,
#      command   => "pcs resource show p_neutron-vpn-agent > /dev/null 2>&1",
#      path      => '/usr/sbin:/usr/bin:/sbin:/bin',
#      unless    => "/bin/grep -r -B5 primary /etc/astute.yaml | /bin/grep $(/bin/uname -n) 2>&1 > /dev/null"
#    }

    exec { "patch-neutron-params":
      path    => "/usr/bin:/usr/sbin:/bin",
      command => "sed 's/neutron-l3-agent/neutron-vpn-agent/g' -i $vpnaas::params::neutron_params_file"
    }

    exec { "patch-cleanup-script":
      path    => "/sbin:/usr/bin:/usr/sbin:/bin",
      command => "sed \"s/'l3':   'neutron-l3-agent'/'l3':   'neutron-vpn-agent'/g\" -i $vpnaas::params::cleanup_script_file"
    }

    exec { "remove-l3-agent":
      path    => "/sbin:/usr/bin:/usr/sbin:/bin",
      command => "pcs resource delete p_neutron-l3-agent",
      onlyif  => "/bin/grep -r -B5 primary /etc/astute.yaml | /bin/grep $(/bin/uname -n) 2>&1 > /dev/null"
    }

    file { "${vpnaas::params::l3_agent_ocf_file}":
      mode   => 644,
      owner  => root,
      group  => root,
      source => "puppet:///modules/vpnaas/neutron-agent-l3"
    }

    class {'vpnaas::agent':
      manage_service => true,
      enabled        => false,
    }

    Exec['remove-l3-agent'] -> Class['vpnaas::agent'] #-> Exec['waiting-for-vpn-agent']

}
