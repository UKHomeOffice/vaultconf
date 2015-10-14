require "vaultconf/version"
require 'curb'
require 'json'
require 'yaml'
require 'helpers'
require 'methadone'

module Vaultconf
  class Vaultconf
    include Methadone::Main
    include Methadone::CLILogging
    def initialize(vault, kube_service)
      @vault=vault
      @kube_service=kube_service
    end

    def self.read_login_from_file
      login_yaml = YAML.load_file("#{Dir.home}/.vaultconf/login")
      return login_yaml['username'], login_yaml['password']
    end

    def reconcile_policies_to_vault(policy_namespace_dir)
      policy_file_names = Array.new
      policy_names = Array.new
      Dir.foreach(policy_namespace_dir) do |namespace|
        next if namespace == '.' or namespace == '..'
        new_policy_file_names = Dir[policy_namespace_dir + '/' + namespace + '/*'].select { |filename| filename != '.' && filename != '..' }
        policy_file_names =policy_file_names.concat(new_policy_file_names)
        policy_names = policy_names.concat(new_policy_file_names.map { |p| namespace + '_' + Helpers.get_policy_name_from_path(p) })
      end
      policies = policy_file_names.zip(policy_names)
      delete_old_policies(@vault, policy_names)
      add_policies(@vault, policies)
    end

    def delete_old_policies(vault, new_policies)
      existing_policies = @vault.sys.policies
      existing_policies.each do |existing_policy|
        unless new_policies.include?(existing_policy) || existing_policy == 'root'
          @vault.sys.delete_policy(existing_policy)
        end
      end
    end

    def add_policies(vault, policies)
      info "Adding policies to vault"
      policies.each do |policy|
        policy_name = policy[1]
        policy_file_name = policy[0]
        policy_yaml = YAML::load_file(policy_file_name)
        policy_json = policy_yaml.to_json.to_s
        @vault.sys.put_policy(policy_name, policy_json)
        debug "#{policy_name} policy written to vault"
      end
    end

    def reconcile_users_to_vault(users_file, configure_kubernetes)
      info "Adding users to vault"
      namespaces = YAML.load_file(users_file)
      output ='{'
      logins = Array.new
      namespaces.each do |namespace|
        users_to_add = namespace[1]
        namespace_name = namespace[0]
        if configure_kubernetes
          debug "Looking for historic users to remove for namespace #{namespace_name}"
          remove_old_users(users_to_add, namespace_name, @vault) # No way to list users in vault so can do this only with kubernetes
          add_new_users_to_vault(logins, namespace_name, users_to_add)
        else
          add_new_users_to_vault(logins, namespace_name, users_to_add)
        end
      end
      return logins
    end

    def add_new_users_to_vault(logins, namespace_name, users_to_add)
      users_to_add.each do |user|
        login = add_user_to_vault(user, namespace_name)
        logins.push(login)
      end
    end

    def remove_old_users(new_users, namespace, vault)
      # Find current users via kubernetes secrets, as vault has no ability to list users
      new_user_names = new_users.map { |new_user| new_user['name'] }
      current_users = @kube_service.get_user_secrets(namespace)
      # Filter out users that are in kubernetes
      users_to_delete = current_users.reject { |current_user| new_users.include?(current_user) }
      users_to_delete.each do |user_to_delete|
        @kube_service.delete_secret("#{user_to_delete}-vault", namespace)
        user_to_delete_vault = user_to_delete.gsub("-", "_")
        @vault.logical.delete("auth/userpass/users/#{user_to_delete_vault}")
      end
    end

    def add_user_to_vault(user, namespace)
      name = user['name']
      policies = user['policies'].map{|policy| "#{namespace}_#{policy}"}.join(',')
      password = Helpers.generate_password
      debug "Writing user #{namespace}_#{name} to vault"
      @vault.logical.write("auth/userpass/users/#{namespace}_#{name}", password: password, policies: policies)
      login = {:namespace => namespace, :username => name, :password => password}
      return login
    end

  end
end