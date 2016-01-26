class puppetfactory::profile::fundamentals (
  $session_id = $puppetfactory::params::session_id,
) inherits puppetfactory::params {

  File {
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  ensure_packages(['gcc', 'zlib-devel'], {
    before => Package['puppetfactory']
  })

  package { ['serverspec', 'puppetlabs_spec_helper']:
    ensure   => present,
    provider => gem,
    require  => Package['puppet'],
  }

  # lol, this is great.
  package { 'puppet':
    ensure          => present,
    provider        => gem,
    install_options => { '--bindir' => '/tmp' },
  }

  class { 'puppetfactory::profile::showoff':
    preso    => 'fundamentals',
    password => $session_id,
  }

  class { 'puppetfactory':
    prefix           => true,
    map_environments => true,
    map_modulepath   => false,
    dashboard        => "${showoff::root}/courseware/fundamentals/_files/tests",
    session_id       => $session_id,
    gitlab_enabled   => false,
  }

  file { '/etc/puppetlabs/r10k/r10k.yaml':
    ensure  => file,
    replace => false,
    source  => 'puppet:///modules/puppetfactory/fundamentals/r10k.yaml',
  }

  $hooks = ['/etc/puppetfactory',
            '/etc/puppetfactory/hooks',
            '/etc/puppetfactory/hooks/create',
            '/etc/puppetfactory/hooks/delete',
          ]

  file { $hooks:
    ensure => directory,
  }

  file { '/etc/puppetfactory/hooks/create/r10k_create_user.rb':
    ensure  => file,
    mode    => '0755',
    content => epp('puppetfactory/fundamentals/r10k_env.rb.epp',{ 'gitserver' => $puppetfactory::gitserver }),
  }

  # this looks wonky, but the script uses its name to determine mode of operation
  file { '/etc/puppetfactory/hooks/delete/r10k_delete_user.rb':
    ensure => link,
    target => '/etc/puppetfactory/hooks/create/r10k_create_user.rb',
  }

  class {'r10k::webhook::config':
    enable_ssl        => false,
    protected         => false,
    use_mcollective   => false,
    prefix            => ':user',
    allow_uppercase   => false,
    repository_events => ['release'],
  }

  class {'r10k::webhook':
    user    => 'root',
    require => Class['r10k::webhook::config'],
  }

  class { 'puppetfactory::facts':
    coursename => 'fundamentals',
  }

  # Because PE writes a default, we have to do tricks to see if we've already managed this.
  # We don't want to stomp on instructors doing demonstrations.
  unless defined('$puppetlabs_class') {
    file { '/etc/puppetlabs/code/hiera.yaml':
      ensure  => file,
      source => 'puppet:///modules/puppetfactory/fundamentals/hiera.yaml',
    }
  }
}