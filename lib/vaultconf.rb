require "vaultconf/version"
require 'curb'
require 'json'
require 'vault'

module Vaultconf
  def self.get_auth_token(username, password, server)
    url = "#{server}/v1/auth/userpass/login/#{username}"
    http = Curl.post(url, '{"password":"' + password + '"}')
    body = JSON.parse(http.body_str)
    return Vault.token = body['auth']['client_token']
  end
end
