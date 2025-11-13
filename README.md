# dehydrated

[![Puppet Forge](http://img.shields.io/puppetforge/v/bzed/dehydrated.svg)](https://forge.puppet.com/bzed/dehydrated)

Centralized CSR signing using Let’s Encrypt™ - keeping your keys safe on the host they belong to.


#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with dehydrated](#setup)
    * [What dehydrated affects](#what-dehydrated-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with dehydrated](#beginning-with-dehydrated)
3. [Usage - Configuration options and additional functionality](#usage)
    * [Monitoring and debugging](#monitoring--debugging)
4. [Migrating from bzed-letsencrypt](#migrating-from-bzed-letsencrypt)
5. [Limitations - OS compatibility, Deployment time, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Description

bzed-dehydrated creates private keys and CSRs, transfers
the CSR to a central host (for example your puppetmaster)
where it is signed using the well known dehydrated
https://github.com/dehydrated-io/dehydrated

Signed certificates are shipped back to the requesting host.

You need to provide an appropriate hook script for dehydrated.
The default is to use the DNS-01 challenge, but if your hook
supports it you could also create the necessary files for http-01.

Let’s Encrypt is a trademark of the Internet Security Research Group. All rights reserved.

### Deprecation of bzed-letsencrypt
With the release of **bzed-dehydrated** my old module *bzed-letsencrypt* will be deprecated.
Renaming the module to avoid trademark related troubles is one of the reasons for a new module,
the other is that I did not want to break the API for all users of the old module.
If there is enough interest I'll change bzed-letsencrypt to become a wrapper around
the new module, but with all the new features and options I don't think that makes much
sense. So I'm sorry for the extra trouble of migrating an existing installation (to make
it easier, see below), but I hope that the extra amount of flexibility and less hacks in the
code make it worth to migrate.

## Setup

### What dehydrated affects

dehydrated needs to use facter to retrieve the signed certificates
and other data from your central signing hosts if you are not using
a puppet master host to handle it. Although only certificates which
need to be renewed are transferred, it is unknown how well this
approach scales if you plan to request lots of certificates. Using
a (designated) puppet master is the better option.

### Setup Requirements

You need to ensure that exported resources are working and pluginsync
is enabled.


### Beginning with dehydrated

Basic things you need:
 -  a host with internet access, preferable a puppet master. This will be known as *dehydrated\_host* now.
 -  a working hook script for dehydrated, for exampes and documentation see [dehydrated-io/dehydrated](https://github.com/dehydrated-io/dehydrated/tree/master/docs)
 -  bzed-dehydrated installed as `dehydrated` module in your Puppet environment.
    You will also need recent versions of `puppetlabs-stdlib`, `puppetlabs-concat`, `puppetlabs-vcsrepo`.
    For puppet >= 6.0 you'll also need `puppetlabs-cron\_core`.
 -  I'd assume at least puppet version 4.8. Not tested or developed for older version.
 -  Working exportable ressources. Make sure your puppetdb is working well, this module
    heavily depends on it.

## Usage

This only describes the very basic usage. Almost all things are configurable, see the reference for details.
So for a basic setup, the following steps should give you a running setup.

 1.  Do a basic setup of your **dehydrated\_host**:
     ```
         class { 'dehydrated' :
             dehydrated_host => 'your.dehydrated.host.example.com',
         }
     ```
 2.  As example we'll use the dehydrated hook for Cloudflare®. Take [socram8888/dehydrated-hook-cloudflare](
     https://github.com/socram8888/dehydrated-hook-cloudflare/blob/master/cf-hook.sh)
     and **on your dehydrated_host** install it into _/opt/dehydrated/hooks/dns-01.sh_
 3.  Add the hook configuration to your config from above:

         class { 'dehydrated' :
             dehydrated_host => 'your.dehydrated.host.example.com',
             dehydrated_environment => {
                 'CF_EMAIL' => 'your@email.address',
                 'CF_KEY'   => 'your-long-Cloudflare-api-key',
             }
         }

 4.  On the host that needs a new certificate, add this to your puppet code:

         class { 'dehydrated' :
             dehydrated_host => 'your.dehydrated.host.example.com',
             challengetype   => 'dns-01',
         }
         ::dehydrated::certificate { 'my-https-host.example.com' :
             subject_alternative_names => [ 'example.com', 'host2.example.com' ],
         }

 5.  Wait.... it will take a few puppet runs until your certificate will appear.
     The certificates will be requestd by a cronjob, not directly from puppet.
     Otherwise puppet runs will take way too much time. For detailed description of the workflow see [Deployment workflow
](#deployment-workflow)

### Using hiera
To use hiera, make sure you include your dehdrated class somewhere. As default configuration for all
hosts setup the defaults, in this case we are using dehydrated in the way to be compatible to the
old bzed-letsencrypt setup:

    dehydrated::dehydrated_host: 'my.dehydrated.host'
    dehydrated::base_dir: '/etc/letsencrypt'
    dehydrated::group: 'letsencrypt'
    dehydrated::letsencrypt_ca: 'v2-production'
    dehydrated::challengetype: 'dns-01'
    dehydrated::dehydrated_hook: 'tophosting_hook.py'
    dehydrated::dehydrated_domain_validation_hook: 'domain_validation_hook.sh'

And to request certificates:

    dehydrated::certificates:
        - "*.subdomain.example.com"
        - "subdomain.example.com"
        - - "san.example.com"
          - [ "second_domain.san.example.com", "third_domain.san.example.com" ]

With the yaml snippet above you'd request the following certificates:
 -  wildcard certificate __*.subdomain.example.com__
 -  "normal" certificate __subdomain.example.com__
 -  SAN certificate __san.example.com__ with **second_domain.san.example.com**
    and **third_domain.san.example.com** as subject alternative names.

### Monitoring & debugging
 -  usual Puppet debugging rules apply >:-)
 -  you'll find the output and errors from the last cronjob run in **/opt/dehydrated/status.json**.
    Unfortunately proper logging and maybe a better error handling is not implemented yet.
    Pull requests are welcome :-)
 -  monitoring the cronjob results is possible by using check\_statusfile. On Debian and derivates
    this is available in the _nagios-plugins-contrib_ package. Or find the source here: [check_statusfile](https://github.com/bzed/pkg-nagios-plugins-contrib/blob/master/dsa/checks/dsa-check-statusfile)

        # /usr/lib/nagios/plugins/check_statusfile /opt/dehydrated/monitoring.status
        dehydrated certificates: OK: 2, FAILED: 1
        foo.example.com (from bar.example.com): some error description


## Migrating from _bzed-letsencrypt_
If you were using the bzed-letsencrypt module before, I'd suggest to use the following settings on the hosts that request certificates:

    class { 'dehydrated' :
        group    => 'letsencrypt',
        base_dir => '/etc/letsencrypt',
    }

Migrating the files on the dehydrated\_host (former letsencrypt\_host) is a harder task and
not implemented. A new setup or manual migration is preferred.

## Reference

An html version of the reference is available here: https://bzed.github.io/bzed-dehydrated/
There is also a markdown version in REFERENCE.md

## Monitoring

The cron-triggered dehydrated worker creates a status file in a format compatible with check\_statusfile, which is - in Debian and derivates - packaged in the _nagios-plugins-contrib_ package.
If you ar enot using Debian you can retrieve the source code here: [check_statusfile](https://github.com/bzed/pkg-nagios-plugins-contrib/blob/master/dsa/checks/dsa-check-statusfile)

## Limitations

Don't forget that Let’s Encrypt limits apply!
Also: this code might not work for your use-case out of the box, please test it properly against
the Let’s Encrypt testing CA instead of running into the limit for failed authorizations and blaiming me for it ;)

### Deployment workflow

The cerfificates take some time to appear on the target host. This is due to the way this modules works. The Following Steps are taken to create all cerficate files. The time depends on your puppet and cron schedule.

|Step|Server|System|Description|Relevant Source|
|----|:-----|:-----|:----------|:--------------|
|1|target|puppet|Create Key and CSR|[dehydrated::certificate](manifests/certificate.pp#L115) [dehydrated::certificate::csr](manifests/certificate/csr.pp#L52-L81)|
|2|target|puppet|get CSR from `$fact['dehydrated_domains']` and export it as a `dehydrated::certificate::request`.|[dehydrated](manifests/init.pp#L217-L222)|
|3|*dehydrated\_host*|puppet|Collect all `dehydrated::certificate::request` and save them for the cronjob.|[dehydrated](manifests/init.pp#L235) [dehydrated::certificate::request](manifests/certificate/request.pp) |
|4|*dehydrated\_host*|cron|finds the files from previous step and requests the certificates.|[dehydrated_job_runner](files/dehydrated_job_runner.rb)|
|5|*dehydrated\_host*|puppet|Find the certificates and export them as `dehydrated::certificate::transfer`|[dehydrated](manifests/init.pp#L243-L247) [dehydrated::certificate:collect](manifests/certificate/collect.pp#L76-L111)|
|6|target|puppet|Collect all `dehydrated::certificate::transfer` and save them to the files.|[dehydrated](manifests/init.pp#L225-L228) [dehydrated::certificate::transfer](manifests/certificate/transfer.pp)|
|7.|target|puppet|identify deployed certificates by `$fact['dehydrated_domains::`*dn*`::'ready_for_merge]` and create joined files like `*_fullchain.pem`.|[dehydrated::certificate](manifests/certificate.pp#L123-L131) [dehydrated::certificate::deploy](manifests/certificate/deploy.pp)|

### PFX on Windows < Server 2019 / Windows 10 1809
To use PKCS#12/PFX files on these Windows releases, you must set **keypbe** and **certpbe** to `PBE-SHA1-3DES` and **macalg** to `sha1`.

Set these parameters as follows:

    dehydrated::pkcs12_certpbe: 'PBE-SHA1-3DES'
    dehydrated::pkcs12_keypbe: 'PBE-SHA1-3DES'
    dehydrated::pkcs12_mac_algorithm: 'sha1'

#### Additional information

OpenSSL Ruby versions earlier than 3.3.0 are not able to set the MAC algorithm. If the `pkcs12_mac_algorithm` parameter is used and the OpenSSL Ruby version is below 3.3.0, Dehydrated automatically uses Puppet’s bundled `openssl.exe` to create the PFX with the specified options.

## Development

Please use the github issue tracker and send pull requests. Make sure that your pull requests keep pdk validate/test unit happy!

### For a release:
 -  Update CHANGELOG.md

 -  Update gh\_pages:

        bundle exec rake strings:gh_pages:update

 -  Update REFERENCE.md:

        puppet strings generate --format markdown --out REFERENCE.md

 -  Release:

        pdk build

 -  Bump version number: bump/change the version in metadata.json.

### Support and help
There is no official commercial support for this puppet module, but I'm happy to help you if you open a bug in the issue tracker.
Please make sure to add enough information about what you have done so far and how your setup looks like.
I'm also reachable by [email](mailto:bernd@bzed.de). Use GPG to encrypt confidential data:

    ECA1 E3F2 8E11 2432 D485  DD95 EB36 171A 6FF9 435F

If you are happy, I also have an [amazon wishlist](https://www.amazon.de/registry/wishlist/1TXINPFZU79GL) :)
