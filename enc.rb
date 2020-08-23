#!/opt/puppetlabs/puppet/bin/ruby
# External Node Classifier (ENC) for Puppet - https://puppet.com/docs/puppet/latest/nodes_external.html
# - Only argument is the name of the node to be classified
# - Returns YAML that can set the environment, assign classes, and set top-scope variables

require 'yaml'

inventory_file = '/etc/puppetlabs/puppet/inventory.yaml'

class Hash
  def deep_merge(h)
    self.merge!(h) {|key, _old, _new| if _old.class == Hash then _old.deep_merge(_new) else _new end  }
  end
end

inventory = YAML.load(File.read(inventory_file))
node = ARGV[0]
output = {}

# Look for the 'nodes' hash in the inventory
if inventory.has_key?('nodes')
  if inventory['nodes'].has_key?(node)
    # node is present in the 'nodes' hash
    node_data = inventory['nodes'][node]
    if node_data.class == String
      if inventory.has_key?(node_data)
        # node assigned to a valid environment
        output['environment'] = node_data
      else
        # node assigned to an environment not defined in inventory
        output['environment'] = "production"
      end
    elsif node_data.nil?
      # node present with no data assigned - default to production environment
      output['environment'] = "production"
    elsif node_data.class == Hash
      if node_data.empty?
        # An empty node hash defaults to the production environment
        output['environment'] = "production"
      else
        # node_data not empty - check environment, default to 'production'
        unless node_data.has_key?('environment')
          output['environment'] = "production"
        end
        # Add node_data to output
        output = output.merge(node_data)
      end
    else
      # node data is invalid - default to production environment
      output['environment'] = "production"
    end
  else
    # node not present in "nodes" hash - set default environment
    output['environment'] = "production"
  end
else
  # "nodes" hash not defined in inventory - set default environment
  output['environment'] = "production"
end


# Merge environment data with node data
if inventory.has_key?(output['environment'])
  unless inventory[output['environment']].nil?
    output = inventory[output['environment']].deep_merge(output)
  end
end

puts output.to_yaml
