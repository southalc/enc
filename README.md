# puppet enc

#### Table of Contents

1. [Description](#description)
1. [Inventory](#inventory)
1. [Setup](#setup)
1. [Reference](#reference)

## Description

A typical Puppet node defines its environment in the local `puppet.conf` file.  Puppet Enterprise provides the ability to classify nodes and assign the environment, but open-
source puppet relies on the client defined environment, which is counter to the concept of centralized management from the puppet master.  Using an External Node Classifier (ENC)
on the puppet server enables environments to be assigned, regardless of client configuration.  In addition to assigning environments, the ENC can also asign classes, class
parameters, and general parameters used as top-scope variables.  Assigning top-scope variables this way can ensure that catalogs are built from controlled data instead of client
supplied facts, and can be an alternative to using trusted facts, which can be cumbersome to implement.

## Inventory

This ENC script is designed to use a YAML inventory for looking up node classification.  It is written in a way that allows environments to be defined with classes, class
parameters, and general parameters used as top-scope variables.  A separate `nodes` hash in the inventory is used to assign nodes to a defined environment.  The `nodes` hash
also permits individual nodes to have classes and parameters assigned, and node data is merged with environment data with node specific data taking precedent in the
event of a conflict.

If a node is not defined in the 'nodes' hash of the inventory file, it simply defaults to the 'production' environment.  To assign a different environment to a node, define the
node in the 'nodes' hash with the syntax: `<node>: <environment>`.  To assign an environment with additional custom settings specific to the node, define the node entry as a hash
and use the syntax `environment: <environment>` in the node data.  The example inventory demonstrates both techniques:

```
---
production:                                          # production environment definition
  classes:                                           # assigned classes hash
    puppet:                                          # the 'puppet' class has no parameters assigned
    ntp:                                             # the 'ntp' class has a class parameter
      ntpserver: 0.pool.ntp.org                      # class parameter `ntpserver` for class `ntp`
  parameters:                                        # top-scope variables hash
    mail_server: mail.example.com                    # this value will take precedent over anything from a manifest

dev:                                                 # 'dev' environment
  classes:                                           # assigned classes hash
    types:                                           # the 'types' module has no parameters assigned
  parameters:                                        # top-scope variables hash
    swallow: african                                 # set a top-scope variable for this entire environment

nodes:                                                # 'nodes' hash 
  node1: dev                                          # 'node1' assigned to 'dev' environment with no additional customizations
  node2:                                              # 'node2' defined as a hash
    environment: dev                                  # 'node2' assigned to 'dev' environment
    parameters:                                       # top-scope variables hash for this node
      swallon: european                               # node-specific parameter overrides the defined environment parameter
  node3: bogus                                        # 'bogus' environment is not defined in the inventory, node defaults to 'production'
```

## Setup

Copy the ENC script `enc.rb` to the puppet server and ensure that it is executable by the 'puppet' user.  Create the inventory file used by the ENC script an modify it as
needed to define your environments and nodes.  The path the the inventory is defined in the `enc.rb` script, so use the default paths per this example or update the value of
`inventory_file` in the ENC script to match your system.
```
cp enc.rb /etc/puppetlabs/puppet/
chown root:puppet /etc/puppetlabs/puppet/enc.rb
chmod 750 /etc/puppetlabs/puppet/enc.rb
touch /etc/puppetlabs/puppet/inventory.yaml
chmod 640 /etc/puppetlabs/puppet/inventory.yaml
```
Configure the puppet server to use the ENC script.  This can be done my manually updating `puppet.conf` and setting the `node_terminus` and `external_nodes` values as shown:
```
[master]
node_terminus = exec
external_nodes = /etc/puppetlabs/puppet/enc.rb
```
You can also use puppet commands to update the configuration programitically:
```
puppet config set --section master node_terminus exec
puppet config set --section master external_nodes /etc/puppetlabs/puppet/enc.rb
```
With the ENC script and inventory in place, you can sanity check the inventory file by executing the ENC script with the name of the node you want to test.  This returns the node
definition in YAML format in the same way as the puppet server will.
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

See the [documentation for external node classifiers]((https://puppet.com/docs/puppet/latest/nodes_external.html) for more details.

