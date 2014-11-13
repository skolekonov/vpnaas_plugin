#

class vpnaas {

    include vpnaas::params

    service { $vpnaas::params::dashboard_service:
      ensure  => running,
      enable  => true,
    }

    exec { "enable_vpnaas_dashboard":
      command => "/bin/sed -i \"s/'enable_vpn': False/'enable_vpn': True/\" $vpnaas::params::dashboard_settings",
      unless  => "/bin/egrep \"'enable_vpn': True\" $vpnaas::params::dashboard_settings",
      notify  => Service[$vpnaas::params::dashboard_service],
    }

    service { 'disable-neutron-l3-service':
      ensure  => stopped,
      name    => "neutron-l3-agent",
      enable  => false,
    }

    service { $vpnaas::params::server_service:
      ensure  => running,
      enable  => true,
    }

    neutron_config {
      'DEFAULT/service_plugins':  value => 'router,vpnaas,metering';
    }

    Neutron_config<||>                    ~> Service[$vpnaas::params::server_service]
    Service['disable-neutron-l3-service'] -> Class['vpnaas::agent']


    class {'vpnaas::agent':}
}
