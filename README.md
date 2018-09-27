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

### Setup Requirements **OPTIONAL**

You need to ensure that exported ressources are working and pluginsync
is enabled.


### Beginning with dehydrated

The very basic steps needed for a user to get the module up and running. This can include setup steps, if necessary, or it can be an example of the most basic use of the module.

## Usage

Include usage examples for common use cases in the **Usage** section. Show your users how to use your module to solve problems, and be sure to include code examples. Include three to five examples of the most important or common tasks a user can accomplish with your module. Show users how to accomplish more complex tasks that involve different types, classes, and functions working in tandem.

## Reference

This section is deprecated. Instead, add reference information to your code as Puppet Strings comments, and then use Strings to generate a REFERENCE.md in your module. For details on how to add code comments and generate documentation with Strings, see the Puppet Strings [documentation](https://puppet.com/docs/puppet/latest/puppet_strings.html) and [style guide](https://puppet.com/docs/puppet/latest/puppet_strings_style.html)

If you aren't ready to use Strings yet, manually create a REFERENCE.md in the root of your module directory and list out each of your module's classes, defined types, facts, functions, Puppet tasks, task plans, and resource types and providers, along with the parameters for each.

For each element (class, defined type, function, and so on), list:

  * The data type, if applicable.
  * A description of what the element does.
  * Valid values, if the data type doesn't make it obvious.
  * Default value, if any.

For example:

```
### `pet::cat`

#### Parameters

##### `meow`

Enables vocalization in your cat. Valid options: 'string'.

Default: 'medium-loud'.
```

## Limitations

In the Limitations section, list any incompatibilities, known issues, or other warnings.

## Development

In the Development section, tell other users the ground rules for contributing to your project and how they should submit their work.

## Release Notes/Contributors/Etc. **Optional**

If you aren't using changelog, put your release notes here (though you should consider using changelog). You can also add any additional sections you feel are necessary or important to include here. Please use the `## ` header.
