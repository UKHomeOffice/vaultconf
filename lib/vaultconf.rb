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

  def self.add_policies_to_vault(vault, policy_namespace_dir)
    Dir.foreach(policy_namespace_dir) do |namespace|
      next if namespace == '.' or namespace == '..'
      Dir.foreach(policy_namespace_dir + '/' + namespace) do |policy_file|
        next if policy_file == '.' or policy_file == '..'
        policy_name = Helpers.remove_file_extension(policy_file)
        policy_raw = File.read(policy_namespace_dir + '/' + namespace + '/' + policy_file)
        vault.sys.put_policy(namespace + '_' + policy_name, policy_raw)
        puts "#{namespace} written to #{policy_name} policy"
      end
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