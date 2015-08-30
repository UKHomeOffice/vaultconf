require "vaultconf/version"
require 'curb'
require 'json'

module Vaultconf
  def self.get_auth_token(username, password, server)
    url = "#{server}/v1/auth/userpass/login/#{username}"
    http = Curl.post(url, '{"password":"' + password + '"}')
    body = JSON.parse(http.body_str)
    token = body['auth']['client_token']
    return token
  end

  def self.add_policies_to_vault(vault, config)
    # Read in each policy in the config directory
    Dir.foreach(config) do |policy_file|
      next if policy_file == '.' or policy_file == '..'
      policy_name = Helpers.remove_file_extension(policy_file)
      vault.logical.write("sys/policy/#{policy_name}", policy: "Yay")
      puts policy_file
    end

    # Add each policy to the vault server

  end
end



module Helpers
  def self.remove_file_extension(filename)
    File.basename(filename, File.extname(filename))
  end
end