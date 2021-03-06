require File.expand_path(File.join(File.dirname(__FILE__), '..', 'nifi'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'ent', 'nifi', 'rest.rb'))
Puppet::Type.type(:nifi_group).provide(:ruby, :parent=> Puppet::Provider::Nifi ) do

  mk_resource_methods

  def initialize(value={})
    super(value)
    config
    @property_flush = {}
  end

  def self.instances
    config

    search_json = Ent::Nifi::Rest.get_all("tenants/user-groups")
    if search_json.nil?
      return []
    end
    groups_raw = search_json['userGroups']
    groups_raw.map do |group_json|
      new(:name => group_json['component']['identity'],
          :ensure => :present
      )
    end

  end

  def self.prefetch(resources)
    # resources parameter is an hash of resources managed by Puppet (catalog)
    resource_instances = instances
    resources.keys.each do |name|
      if provider = resource_instances.find{ |r| r.name == name }
        resources[name].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end



  def create_group
    #Example post
    # {
    #   "revision": {
    #   "clientId": "value",
    #   "version": 0,
    #   "lastModifier": "value"
    # },
    #   "id": "value",
    #   "uri": "value",
    #   "position": {
    #   "x": 0.0,
    #   "y": 0.0
    # },
    #   "permissions": {
    #   "canRead": true,
    # "canWrite": true
    # },
    #   "bulletins": [{
    #                   "id": 0,
    #   "groupId": "value",
    #   "sourceId": "value",
    #   "timestamp": "value",
    #   "nodeAddress": "value",
    #   "canRead": true,
    # "bulletin": {…}
    # }],
    #   "component": {
    #   "id": "value",
    #   "parentGroupId": "value",
    #   "position": {…},
    #   "identity": "value",
    #   "userGroups": [{…}],
    #   "accessPolicies": [{…}]
    # }
    # }
    groupname = @resource[:name]
    req_json = %Q{
      {
        "revision": {
          "version": 0
        },
        "id": null,
        "uri": null,
        "position": {
          "x": 0.0,
          "y": 0.0
        },
        "permissions": {
          "canRead": true,
          "canWrite": true
        },
        "component": {
          "id": null,
          "parentGroupId": null,
          "identity": "#{groupname}",
          "users": [],
          "accessPolicies": []
        }
      }
    }
    config
    Ent::Nifi::Rest.node_ok(@resource[:require_cluster])
    Ent::Nifi::Rest.create("tenants/user-groups", JSON.parse(req_json))
  end

  def delete_group(groupname)
    config
    Ent::Nifi::Rest.node_ok(@resource[:require_cluster])
    groups = Ent::Nifi::Rest.get_groups
    found=groups.select do |group|
      group['component']['identity']==groupname
    end
    if ! found.nil? and ! found[0].nil?
      group_id = found[0]['id']
      version = found[0]['revision']['version']
      Ent::Nifi::Rest.destroy("tenants/user-groups/#{group_id}", 'puppet', version)
    end
  end

  def create
    create_group
    @property_hash[:ensure] = :present
  end

  def destroy
    delete_group(@resource[:name])
    @property_hash.clear
    @property_hash[:ensure] = :absent
  end

  def refresh
    # ...
  end

  # Called once after Puppet creates, destroys or updates a resource
  def flush
    if @property_flush
      # update resource here
      @property_flush.clear
      @property_hash = resource.to_hash
    end
  end
end