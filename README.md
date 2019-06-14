puppet-spiped
========

[![Build Status](https://travis-ci.org/chriskuehl/puppet-spiped.svg)](https://travis-ci.org/chriskuehl/puppet-spiped)

Puppet module for configuring [spiped][spiped] tunnels.

## Requirements

* Debian >= 8 / Ubuntu >= 15.04 / similar systems
* systemd as init

The init requirement rules out many versions of Debian or Ubuntu. If you can't
run systemd as init, this module is not useful to you.

## Usage

For example, let's say we have a host `redis-host` which hosts a Redis
database. Many clients will connect to it.

On `redis-host`, we would define a server tunnel:

```puppet
spiped::tunnel::server { 'redis':
  source_host        => '0.0.0.0',
  source_port        => 1234,
  target_socket_file => '/var/run/redis.sock',
  secret             => 'hunter2',
}
```

On clients, we would define a client tunnel:

```puppet
spiped::tunnel::client { 'redis':
  source_socket_file => '/var/run/redis.sock',
  target_ip          => 'redis-host',
  target_host        => 1234,
  secret             => 'hunter2',
}
```

The secret is an arbitrarily-long shared symmetric key. The options above are
the only supported; this module is kept as simple as possible.

[spiped]: https://www.tarsnap.com/spiped.html
