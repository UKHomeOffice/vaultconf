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
    read_policy = File.read(policies_path + '/reader.json').gsub(/\s+/, '')
    writer_policy = File.read(policies_path + '/writer.json').gsub(/\s+/, '')
    expected_writer_url = "http://#{@@server}/v1/sys/policy/reader"

    writer_policy_stub = stub_request(:put, expected_writer_url).
        with(:body => read_policy).
        to_return(:status => 200, :body => "", :headers => {})

    reader_policy_stub = stub_request(:put, "http://localhost:8200/v1/sys/policy/writer").
        with(:body => writer_policy).
        to_return(:status => 200, :body => "", :headers => {})


    Vaultconf.add_policies_to_vault(Vault, policies_path)

    assert_requested(writer_policy_stub)
    assert_requested(reader_policy_stub)

  end
end
