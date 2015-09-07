require 'test/unit'
require 'webmock/test_unit'
require 'vaultconf.rb'
require 'vault'

class TestLogin < Test::Unit::TestCase
  @@server = 'localhost:8200'
  @@user = 'mike'
  @@password = 'xdf32'
  Vault.address = "http://#{@@server}"
  Vault.token = 'testtoken'

  def test_login

    expected_auth_token = 'authtoken123'
    stub_request(:post, "http://#{@@server}/v1/auth/userpass/login/#{@@user}").
        with(:body => "{\"password\":\"#{@@password}\"}").
        to_return(:status => 200, :body => '{"lease_id":"","renewable":false,"lease_duration":0,"data":null,
          "auth":{"client_token":"'+expected_auth_token+'","policies":["root"],"metadata":{"username":"user"},
          "lease_duration":0,"renewable":false}}', :headers => {})

    auth_token = Vaultconf.get_auth_token(@@user, @@password, @@server)

    assert auth_token = expected_auth_token
  end

  def test_add_policies_to_vault
    policies_path = File.expand_path('../resources/policies', __FILE__)

    reader_policy_stub = stub_request(:put, "http://#{@@server}/v1/sys/policy/reader").
        to_return(:status => 200, :body => "", :headers => {})

    writer_policy_stub = stub_request(:put, "http://#{@@server}/v1/sys/policy/writer").
        to_return(:status => 200, :body => "", :headers => {})

    Vaultconf.add_policies_to_vault(Vault, policies_path)

    assert_requested(writer_policy_stub)
    assert_requested(reader_policy_stub)

  end

  def test_add_users_to_vault
    users_path = File.expand_path('../resources/users/users.yaml', __FILE__)

    user_request_stub_writer = stub_request(:put, "http://#{@@server}/v1/auth/userpass/users/MrWrite").
        with(:body => /{\"password\":\".*\",\"policies\":\"writer,reader\"}/).
        to_return(:status => 200, :body => "", :headers => {})

    user_request_stub_reader = stub_request(:put, "http://#{@@server}/v1/auth/userpass/users/MrRead").
        with(:body => /{\"password\":\".*\",\"policies\":\"reader\"}/).
        to_return(:status => 200, :body => "", :headers => {})

    Vaultconf.add_users_to_vault(Vault, users_path)
    assert_requested(user_request_stub_writer)
    assert_requested(user_request_stub_reader)

  end
end
