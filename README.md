# puppet enc

#### Table of Contents

1. [Description](#description)
1. [Inventory](#inventory)
1. [Setup](#setup)
1. [Reference](#reference)

## Description

A typical Puppet node defines its environment in the local `puppet.conf` file.  Puppet Enterprise provides the ability
to classify nodes and assign the environment, but open-source puppet relies on the client defined environment, which
is counter to the concept of centralized management from the puppet master.  Aside from environments, even Puppet
Enterprise provides no way to assign variables directly to a node without writing site manifests.  I had previously
used Puppet with [The Foreman](https://theforeman.org) and liked the flexibility it provided for node classification.
This project provides similar capability for Puppet and can run with a lot less hardware resources than Foreman.

Using an External Node Classifier (ENC) on the puppet server enables environments to be assigned regardless of client
configuration.  In addition to assigning environments, the ENC can also asign classes, class parameters, and general
parameters used as top-scope variables.  Assigning top-scope variables this way can ensure that catalogs are built from
controlled data instead of client-supplied facts, and can be an alternative to using trusted facts, which can be
cumbersome to implement.

You can still use site manifests with an ENC (but why?) and node data supplied by the ENC will be merged with data
from any nvironment manifests in building the catalog for a node.  In the event of any conflict, the data from the ENC
will take precedent.

## Inventory

This ENC script is designed to use a YAML inventory for looking up node classification.  It is written in a way that
allows environments to be defined with classes, class parameters, and general parameters used as top-scope variables.
A separate `nodes` hash in the inventory is used to assign nodes to a defined environment.  The `nodes` hash also
permits individual nodes to have classes and parameters assigned.  Node and environment data from the inventory will be
merged, with node data taking precedent inthe event of a conflict.

If a node is not defined in the 'nodes' hash of the inventory file, it simply defaults to the 'production' environment.
To assign a different environment to a node, define the node in the 'nodes' hash with the syntax: `<node>: <environment>`.
To assign an environment with additional custom settings specific to the node, define the node entry as a has
and use the syntax `environment: <environment>` in the node data.  The example inventory demonstrates both techniques:

```
---
production:                                          # production environment definition
  classes:                                           # assigned classes hash
    puppet:                                          # the 'puppet' class has no parameters assigned
    ntp:                                             # the 'ntp' class has a class parameter
      ntpserver: 0.pool.ntp.org                      # class parameter `ntpserver` for class `ntp`
  parameters:                                        # top-scope variables hash
    mail_server: mail.example.com                    # set a top-scope variable for this environment

dev:                                                 # 'dev' environment
  classes:                                           # assigned classes hash
    types:                                           # the 'types' module has no parameters assigned
  parameters:                                        # hash for top-scope variables
    swallow: african                                 # set a top-scope variable for this environment

test:                                                # 'test' environment - has no classes or parameters assigned

nodes:                                               # 'nodes' hash 
  node1: dev                                         # 'node1' assigned to 'dev' environment with no parameters
  node2:                                             # 'node2' defined as a hash
    environment: dev                                 # 'node2' assigned to 'dev' environment
    classes:                                         # 'node2' has classes included from the ENC
      - types                                        # The 'types' module is included
    parameters:                                      # top-scope variables hash for this node
      swallow: european                              # node-specific parameter overrides the defined environment parameter
  node3: bogus                                       # 'bogus' environment not in inventory, node reverts to 'production'
```

## Setup

Copy the ENC script `enc.rb` to the puppet server and ensure that it is executable by the 'puppet' user.  Create the
inventory file used by the ENC script an modify it as needed to define your environments and nodes.  The path the the
inventory is defined in the `enc.rb` script, so use the default paths per this example or update the value of
`inventory_file` in the ENC script to match your system.
```
cp enc.rb /etc/puppetlabs/puppet/
chown root:puppet /etc/puppetlabs/puppet/enc.rb
chmod 750 /etc/puppetlabs/puppet/enc.rb
touch /etc/puppetlabs/puppet/inventory.yaml
chmod 640 /etc/puppetlabs/puppet/inventory.yaml
```
Configure the puppet server to use the ENC script.  This can be done my manually updating `puppet.conf` and setting
the `node_terminus` and `external_nodes` values as shown:
```
[master]
node_terminus = exec
external_nodes = /etc/puppetlabs/puppet/enc.rb
```
You can also use puppet commands to update the configuration programmatically:
```
puppet config set --section master node_terminus exec
puppet config set --section master external_nodes /etc/puppetlabs/puppet/enc.rb
```
Ensure you restart the Puppet server after updating the configuration to use the ENC.

With the ENC script and inventory in place, you can sanity check the inventory file by executing the ENC script with
the name of the node you want to test.  This returns the ENC node data in YAML format in the same way it will be seen
by the Puppet server.
```
/etc/puppetlabs/puppet/enc.rb node1
---
classes:
  types: 
parameters:
  swallow: african
environment: dev
```

## Reference

See the [documentation for external node classifiers](https://puppet.com/docs/puppet/latest/nodes_external.html) for more details.

