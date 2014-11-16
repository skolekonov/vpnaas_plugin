class vpnaas_ha {

    include vpnaas::params

    exec { "patch-neutron-params":
      path    => "/usr/bin:/usr/sbin:/bin",
      command => "sed 's/neutron-l3-agent/neutron-vpn-agent/g' -i $neutron_params_file"
    }

    exec { "patch-cleanup-script":
      path    => "/usr/bin:/usr/sbin:/bin",
      command => "sed \"s/'l3':   'neutron-l3-agent'/'l3':   'neutron-vpn-agent'/g\" -i $cleanup_script_file"
    }

    exec { "remove-l3-agent":
      path    => "/usr/bin:/usr/sbin:/bin",
      command => "pcs resource delete p_neutron-l3-agent"
    }

    file { "${l3_agent_ocf_file}":
      mode   => 644,
      owner  => root,
      group  => root,
      source => "puppet:///modules/vpnaas_ha/neutron-agent-l3"
    }

    class {'vpnaas::agent':
      manage_service => false,
      enabled        => false,
    }

    Exec['remove-l3-agent'] -> Class['vpnaas::agent']

}
