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

  # Could improve this by running a server in Ruby code and grabbing the root token for further actions.... but it is a pain
  # @server = fork do
  #   exec "vault server -dev"
  # end
  # Process.detach(@server)
end


When(/^I run vaultconf policies mypolicylocation \-u user \-p password \-\-server http:\/\/localhost:8200$/) do
  policy_path = File.expand_path('../../support/policies', __FILE__)
  Dir.foreach(policy_path) do |policy_file|
    next if policy_file == '.' or policy_file == '..'
    # do work on real items
    puts policy_file
  #   TODO: Look at the methadone tutorial to see how I can call my command line application from here
  end
end