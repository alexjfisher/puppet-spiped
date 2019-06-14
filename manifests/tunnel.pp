define spiped::tunnel(
  Enum['client','server'] $type,

  Optional[Stdlib::Unixpath] $source_socket_file = undef,
  Optional[Stdlib::Host]     $source_host = undef,
  Optional[Stdlib::Port]     $source_port = undef,

  Optional[Stdlib::Unixpath] $target_socket_file = undef,
  Optional[Stdlib::Host]     $target_host = undef,
  Optional[Stdlib::Port]     $target_port = undef,

  Variant[Sensitive[String[1]],String[1]] $secret,
) {
  assert_private()

  if $source_socket_file {
    if $source_host { fail('`source_host` must not be specified when using `source_socket_file`') }
    if $source_port { fail('`source_port` must not be specified when using `source_socket_file`') }
    $source_socket = $source_socket_file
  } else {
    unless $source_host and $source_port { fail('either `source_socket_file` or `source_host` and `source_port must be specified') }
    $source_socket = $source_host ? {
      Stdlib::IP::Address => "[${source_host}]:${source_port}",
      Stdlib::Fqdn        => "${source_host}:${source_port}",
    }
  }

  if $target_socket_file {
    if $target_host { fail('`target_host` must not be specified when using `target_socket_file`') }
    if $target_port { fail('`target_port` must not be specified when using `target_socket_file`') }
    $target_socket = $target_socket_file
  } else {
    unless $target_host and $target_port { fail('either `target_socket_file` or `target_host` and `target_port must be specified') }
    $target_socket = $target_host ? {
      Stdlib::IP::Address => "[${target_host}]:${target_port}",
      Stdlib::Fqdn        => "${target_host}:${target_port}",
    }
  }

  ensure_packages(['spiped'])
  ensure_resource('file', '/etc/spiped', {'ensure' => 'directory'})

  $keyfile = "/etc/spiped/${title}.key"

  file { $keyfile:
    owner     => root,
    group     => root,
    mode      => '0600',
    show_diff => false,
    content   => $secret,
  }

  # Previous versions created a unit file here.
  file { "/lib/systemd/system/spiped-${title}.service":
    ensure => absent,
    before => Systemd::Unit_file["spiped-${title}.service"],
  }

  systemd::unit_file { "spiped-${title}.service":
    content => epp(
      'spiped/service.epp',
      {
        'name'          => $title,
        'type'          => $type,
        'keyfile'       => $keyfile,
        'source_socket' => $source_socket,
        'target_socket' => $target_socket,
      },
    ),
  }

  service { "spiped-${title}":
    ensure    => running,
    enable    => true,
    subscribe => Systemd::Unit_file["spiped-${title}.service"],
  }
}
