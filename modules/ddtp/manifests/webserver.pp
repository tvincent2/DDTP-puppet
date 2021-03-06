# This is a puppet manifest for the webserver config of the DDTP

class ddtp::webserver::server {
	if $enable_ssl {
		include ddtp::webserver::ssl
	}

	package { 'apache2': }

	# Run webserver
	service { 'apache2':
		enable => true,
		ensure => running,
		require => [Package['apache2']],
	}
}

class ddtp::webserver {
	# Remove default site
	file { '/etc/apache2/sites-enabled/000-default.conf':
		ensure => absent,
		require => Package['apache2'],
	}

	# Create log directory
	file { "/var/log/apache2/$server_name":
		ensure => directory,
		owner => root,
		group => adm,
		before => Service['apache2'],
	}

	# Add DDTP site config
	file { '/etc/apache2/sites-available/ddtp.debian.net.conf':
		ensure => present,
		require => Package['apache2'],
		content => template('ddtp/ddtp.debian.net.erb'),
		mode => 'u=rw,og=r',
		owner => root,
		group => root,
		notify => Service['apache2'],
	}

	file { '/etc/apache2/sites-enabled/ddtp.debian.net.conf':
		ensure => '../sites-available/ddtp.debian.net.conf',
		before => Service['apache2'],
	}

	# Enable required modules
	file { '/etc/apache2/mods-enabled/rewrite.load':
		ensure => '../mods-available/rewrite.load',
		before => Service['apache2'],
	}

	file { '/etc/apache2/mods-enabled/cgi.load':
		ensure => '../mods-available/cgi.load',
		before => Service['apache2'],
	}

	file { '/etc/apache2/mods-enabled/socache_shmcb.load':
		ensure => '../mods-available/socache_shmcb.load',
		before => Service['apache2'],
	}

	file { '/etc/apache2/mods-enabled/ssl.load':
		ensure => '../mods-available/ssl.load',
		before => Service['apache2'],
	}

	file { '/etc/apache2/mods-enabled/ssl.conf':
		ensure => '../mods-available/ssl.conf',
		before => Service['apache2'],
	}
}

# Handle the SSL certificates, creates one if it doesn't exist.
class ddtp::webserver::ssl {
	package { 'ssl-cert': }

	file { '/srv/admin':
		ensure => directory
	}
	file { '/srv/admin/ssl':
		ensure => directory
	}

	file { "/srv/admin/ssl/$server_name.cnf":
		content => template('ddtp/ddtp.ssl.cnf'),
	}

	exec { 'make-default-ssl':
		command => "/usr/sbin/make-ssl-cert /srv/admin/ssl/$server_name.cnf /srv/admin/ssl/$server_name.pem",
		creates => "/srv/admin/ssl/$server_name.pem",
		require => File["/srv/admin/ssl/$server_name.cnf"],
	}
}
