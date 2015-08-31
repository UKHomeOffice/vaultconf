require 'curb'
require 'vault'

Given(/^I have a vault server running$/) do
  # This step just requires that outside of these tests you have a vault server running in dev mode, with the user auth backend enabled,
  # and a user of "user" with password "password" that has root access

  # To start the server you must do:
  # vault server -dev
  # vault auth-enable userpass
  # vault write auth/userpass/users/user password=password policies=root
  address = 'http://127.0.0.1:8200'
  Vault.address = address
  username = 'user'
  loginUrl = "#{address}/v1/auth/userpass/login/#{username}"
  http = Curl.post(loginUrl, '{"password":"password"}')
  body = JSON.parse(http.body_str)
  Vault.token = body['auth']['client_token']

  puts Dir.pwd
  # Could improve this by running a server in Ruby code and grabbing the root token for further actions.... but it is a pain
  # @server = fork do
  #   exec "vault server -dev"
  # end
  # Process.detach(@server)
end


When(/^I do "vaultconf \-c test\/resources\/policies \-u user \-p password \-a http:\/\/localhost:8200"$/) do
  `bundle exec bin/vaultconf policies test/resources/policies -u user -p password -a http://localhost:8200 -c test/resources/policies`
end

Then(/^I should be able to see these policies in vault$/) do
  policies = Vault.sys.policies
#   TODO: Add assertion that checks that the policies that have been added are only reader and writer

#   TODO: Add an after hook that removes all policies from vault
end
