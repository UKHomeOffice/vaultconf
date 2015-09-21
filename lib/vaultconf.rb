require "vaultconf/version"
require 'curb'
require 'json'
require 'yaml'
require 'helpers'

module Vaultconf
  def self.get_auth_token(username, password, server)
    url = "#{server}/v1/auth/userpass/login/#{username}"
    http = Curl.post(url, '{"password":"' + password + '"}')
    body = JSON.parse(http.body_str)
    token = body['auth']['client_token']
    return token
  end

  def self.reconcile_policies_to_vault(vault, policy_namespace_dir)
    Dir.foreach(policy_namespace_dir) do |namespace|
      next if namespace == '.' or namespace == '..'
      policy_file_names = Dir[policy_namespace_dir + '/' + namespace + '/*'].select { |filename| filename != '.' && filename != '..' }
      policy_names = policy_file_names.map { |p| namespace + '_' + Helpers.get_policy_name_from_path(p) }


      Vaultconf.add_policies(vault, policy_file_names, namespace)
      Vaultconf.delete_old_policies(vault, policy_names)
    end
  end

  def self.delete_old_policies(vault, new_policies)
    existing_policies = vault.sys.policies
    existing_policies.each do |existing_policy|
      unless new_policies.include?(existing_policy) || existing_policy == 'root'
        vault.delete(existing_policy)
      end
    end
  end

  def self.add_policies(vault, policy_file_names, namespace)
    policy_file_names.each do |policy_file_name|
      policy_name = Helpers.get_policy_name_from_path(policy_file_name)
      policy_raw = File.read(policy_file_name)
      vault.sys.put_policy(namespace + '_' + policy_name, policy_raw)
      puts "#{namespace} written to #{policy_name} policy"
    end
  end

  def self.add_users_to_vault(vault, users_file)
    namespaces = YAML.load_file(users_file)
    output ='{'
    logins = Array.new
    namespaces.each do |namespace|
      users = namespace[1]
      users.each do |user|
        name = user['name']
        policies = user['policies'].join(',')
        password = Helpers.generate_password
        vault.logical.write("auth/userpass/users/#{namespace[0]}_#{name}", password: password, policies: policies)
        login = {:namespace => namespace[0], :username => name, :password => password}
        logins.push(login)
      end
    end
    return logins
  end

end