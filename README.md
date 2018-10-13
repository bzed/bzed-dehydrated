# dehydrated

[![Puppet Forge](http://img.shields.io/puppetforge/v/bzed/dehydrated.svg)](https://forge.puppetlabs.com/bzed/dehydrated) [![Build Status](https://travis-ci.org/bzed/bzed-dehydrated.png?branch=master)](https://travis-ci.org/bzed/bzed-dehydrated)

Centralized CSR signing using Let’s Encrypt™ - keeping your keys safe on the host they belong to.


#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with dehydrated](#setup)
    * [What dehydrated affects](#what-dehydrated-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with dehydrated](#beginning-with-dehydrated)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)

## Description

bzed-dehydrated creates private keys and CSRs, transfers
the CSR to a central host (for example your puppetmaster)
where it is signed using the well known dehydrated
https://github.com/lukas2511/dehydrated

Signed certificates are shipped back to the requesting host.

You need to provide an appropriate hook script for dehydrated.
The default is to use the DNS-01 challenge, but if your hook
supports it you could also create the necessary files for http-01.

Let’s Encrypt is a trademark of the Internet Security Research Group. All rights reserved.

## Setup

### What dehydrated affects

dehydrated needs to use facter to retrieve the signed certificates
and other data from your central signing hosts if you are not using
a puppet master host to handle it. Although only certificates which
need to be renewed are transferred, it is unknown how well this
approach scales if you plan to request lots of certificates. Using
a (designated) puppet master is the better option.

### Setup Requirements 

You need to ensure that exported ressources are working and pluginsync
is enabled.


### Beginning with dehydrated

The very basic steps needed for a user to get the module up and running. This can include setup steps, if necessary, or it can be an example of the most basic use of the module.

## Usage

Include usage examples for common use cases in the **Usage** section. Show your users how to use your module to solve problems, and be sure to include code examples. Include three to five examples of the most important or common tasks a user can accomplish with your module. Show users how to accomplish more complex tasks that involve different types, classes, and functions working in tandem.

## Reference

An html version of the reference is available here: https://bzed.github.io/bzed-dehydrated/

## Monitoring

The cron-triggered dehydrated worker creates a status file in a format compatible with check\_statusfile, which is - in Debian and derivates - packaged in the _nagios-plugins-contrib_ package.
If you ar enot using Debian you can retrieve the source code here: https://github.com/bzed/pkg-nagios-plugins-contrib/blob/master/dsa/checks/dsa-check-statusfile

## Limitations

Don't forget that Let’s Encrypt limits apply!
Also: this code might not work for your use-case out of the box, please test it properly against
the Let’s Encrypt testing CA instead of running into the limit for failed authorizations and blaiming me for it ;)

## Development

Please use the github issue tracker and send pull requests. Make sure that your pull requests keep travis happy!

