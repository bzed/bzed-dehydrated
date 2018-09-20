# Setup dehydrated and necessary files and folders
# on $::dehydrated::dehydrated_host. Don't use it in
# your code.
#
# @summary setup dehydrated and users/groups for it
#
# @api private

class dehydrated::setup::dehydrated_host {
  if ! defined(Class['dehydrated']) {
    fail('You must include the dehydrated base class first; also this class is not supposed to be included on its own.')
  }

  if ($facts['kernel'] == 'windows') {
    fail('Running dehydrated on windows is not supported (yet - patches welcome).')
  }

  if ($::dehydrated::manage_user) {
    if ($::dehydrated::dehydrated_group != $::dehydrated::group) {
      group { $::dehydrated::dehydrated_group :
        ensure => present,
      }
    }

    if ($::dehydrated::dehydrated_user != $::dehydrated::user) {
      user { $::dehydrated::dehydrated_user :
        ensure     => present,
        gid        => $::dehydrated::dehydrated_group,
        home       => $::dehydrated::dehydrated_base_dir,
        shell      => '/bin/bash',
        managehome => false,
        password   => '!!',
        require    => Group[$::dehydrated::dehydrated_group],
      }
    }
  }

  File {
    owner   => $::dehydrated::dehydrated_user,
    group   => $::dehydrated::dehydrated_group,
    mode    => '0750',
    require => [
      User[$::dehydrated::dehydrated_user],
      Group[$::dehydrated::dehydrated_group],
    ],
  }

  file { [
    $::dehydrated::dehydrated_base_dir,
    $::dehydrated::dehydrated_requests_dir,
    $::dehydrated::dehydrated_wellknown_dir
    ] :
  }

  vcsrepo { $::dehydrated::dehydrated_git_dir :
    ensure   => latest,
    revision => $::dehydrated::dehydrated_git_tag,
    provider => git,
    source   => $::dehydrated::dehydrated_git_url,
    user     => $::dehydrated::dehydrated_user,
    require  => [
      File[$::dehydrated::dehydrated_base_dir],
      Package['git']
    ],
  }

  if ($::dehydrated::manage_packages) {
    ensure_packages($::dehydrated::dehydrated_host_packages)
  }

  concat { $::dehydrated::dehydrated_requests_config :
    ensure => present,
    format => 'json-pretty',
  }


}
