# Puppet PBIS

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with Puppet PBIS](#setup)
    * [What Puppet PBIS affects](#what-Puppet-PBIS-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with Puppet PBIS](#beginning-with-Puppet-PBIS)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)

## Overview

This module manages the joining of a Linux server to an Active Directory domain.

## Module Description

The PBIS module does four things; installs PBIS, joins a domain, sets the
default domain and shell and configures user access. There is a service account
that the module uses which has permissions to join servers to the domain and
place them in the proper OU. The password for this account is kept in an eyaml
file as Hiera data. The domain and organizational unit parameters are also set
using Hiera data.

## Setup

### What Puppet PBIS affects

* The PBIS module installs the pbis-open package from their repository.
* It configures which domain the server joins as well as which organizational
  unit the object is placed in
* The default domain is set to true
* The default shell is set to /bin/bash
* Three Active Directory security groups are granted access via this module
  * server_admins
  * $hostname_admins
  * $hostname_users
  the server should be AD authenticated or not

### Setup Requirements

* Puppet >= 3.6.2
* Facter >= 1.7
* PBIS >= 7.0
* PluginSync enabled

### Beginning with Puppet PBIS

In order to use the PBIS module you require access to the PBIS repository, a
service account with proper permissions in AD and a password for said service
account. You can set the default values for the parameters inside the module,
or if you need to be more flexible and especially more secure with your service
account password you can store the data in Hiera as encrypted yaml.

## Usage

An example using Hiera data

```yaml
---
# domain join data
pbis::password: >
    ENC[PKCS7,MIIBeQYJKoZIhvcNAQcDoIIBajCCAWYCAQAxggEhMIIBHQIBADAFMAACAQEw
    DQYJKoZIhvcNAQEBBQAEggEAYZLuXn1uIUVg1PeL/GKorqXrSMp2yFGSxu4M
    W9jCSN0pzmeYBq4k09Vtylu9s7sUNQdavpip6oVOaMqhpRKp8RLWEC/eYPbp
    Hi6F8M08716FWUVfhd63kd93kIs9sUEpMk66ctIrrvf/A72nmTAlnvb1GWLo
    I3eCB8YIJU7lMwuxcoOW1Ag9ftaCqCk2mX8IXR73+mWCqyPClGG1lPoRx6kL
    SQcGWE1OW2HifBXnkzYvBbtsMt9cK0nsuCd3LuysNJl0AItrZ8rKHJpOOvZy
    hUmna5udzOJMYjUTEQqXsLXmOgPqDWxChJ8YAqoeh7nszqvXKVSbTMcEvHAW
    4BDGkDA8BgkqhkiG9w0BBwEwHQYJYIZIAWUDBAEqBBA6iZlyTe074X4L5P99
    tixWgBCKxI4PdupfWEQ1F+UnNQP7]
pbis::domain: foo.com
pbis::org_unit: servers
```

## Reference

Classes:

* [pbis](#clas$as-pbis)

## Limitations

This module is tested and compatible with CentOS 5,6 and RHEL 5,6. There has
been no CentOS 7 or RHEL 7 testing thus far.
