require "vaultconf/version"
require 'curb'
require 'json'
require 'yaml'
require 'securerandom'

module Vaultconf
  def self.get_auth_token(username, password, server)
    url = "#{server}/v1/auth/userpass/login/#{username}"
    http = Curl.post(url, '{"password":"' + password + '"}')
    body = JSON.parse(http.body_str)
    token = body['auth']['client_token']
    return token
  end

  def self.add_policies_to_vault(vault, policy_namespace_dir)
    Dir.foreach(policy_namespace_dir) do |policy_dir|
      next if policy_dir == '.' or policy_dir == '..'
      Dir.foreach(policy_namespace_dir + '/' + policy_dir) do |policy_file|
        next if policy_file == '.' or policy_file == '..'
        policy_name = Helpers.remove_file_extension(policy_file)
        policy_raw = File.read(policy_namespace_dir + '/' + policy_dir + '/' + policy_file)
        vault.sys.put_policy(policy_dir + '/' + policy_name, policy_raw)
        puts "#{policy_dir} written to #{policy_name} policy"
      end
    end
  end

  def self.add_users_to_vault(vault, users_file)
    users = YAML.load_file(users_file)['users']
    output ='{'
    users.each do |user|
      name = user['name']
      policies = user['policies'].join(',')
      password = Helpers.generate_password
      vault.logical.write("auth/userpass/users/#{name}", password: password, policies: policies)
      output = output + "\"#{name}\":\"#{password}\","
    end
    output = output[0...-1]+'}'
    puts output
  end

end

module Helpers
  def self.remove_file_extension(filename)
    File.basename(filename, File.extname(filename))
  end

  def self.generate_password
    return SecureRandom.hex
  end
end