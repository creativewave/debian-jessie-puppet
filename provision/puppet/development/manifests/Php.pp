# Php.pp
class cw_php (
  Array $modules = [],
  Hash  $pool    = {},
  Hash  $conf    = {},
  Hash  $xdebug  = {}
) {

  # Install and run PHP-FPM
  package { 'php7.3-fpm': }
  -> service { 'php7.3-fpm': hasrestart => true }

  # Install modules
  ensure_packages($modules, { notify => Service['php7.3-fpm'] })

  # Configure PHP-FPM pools
  $pool.each |$pool_name, $conf| {
    $conf.each |$key, $value| {
      augeas { "pool/${key}: ${value}":
        lens    => 'PHP.lns',
        incl    => '/etc/php/7.3/fpm/pool.d/www.conf',
        changes => ["set ${pool_name}/${key} '${value}'"],
        notify  => Service['php7.3-fpm'],
      }
    }
  }

  # Configure PHP
  file { '/etc/php/7.3/fpm/conf.d/99-custom.ini': replace => no }
  $conf.each |$key, $value| {
    augeas { "custom/${key}: ${value}":
      lens    => 'PHP.lns',
      incl    => '/etc/php/7.3/fpm/conf.d/99-custom.ini',
      changes => ["set custom/${key} '${value}'"],
      notify  => Service['php7.3-fpm'],
    }
  }

  # Configure Xdebug
  $xdebug.each |$key, $value| {
    augeas { "xdebug/${key}: ${value}":
      lens    => 'PHP.lns',
      incl    => '/etc/php/7.3/fpm/conf.d/99-custom.ini',
      changes => ["set xdebug/${key} '${value}'"],
      notify  => Service['php7.3-fpm'],
    }
  }

  # Install Composer
  exec { 'composer':
    command => 'wget -qO - https://raw.githubusercontent.com/composer/getcomposer.org/master/web/installer | sudo php -- --install-dir /usr/bin/ --filename composer',
    creates => '/user/bin/composer',
    path    => '/usr/bin',
  }
}
