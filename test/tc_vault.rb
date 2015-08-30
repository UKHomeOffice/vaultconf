require 'test/unit'
require 'webmock/test_unit'
require 'vaultconf.rb'
require 'vault'

class TestLogin < Test::Unit::TestCase
  @@server = 'localhost:8200'
  @@user = 'mike'
  @@password = 'xdf32'
  @@expected_auth_token = 'authtoken123'
  Vault.address = "http://#{@@server}"
  Vault.token = 'testtoken'
  def test_login

    stub_request(:post, "http://#{@@server}/v1/auth/userpass/login/#{@@user}").
        with(:body => "{\"password\":\"#{@@password}\"}").
        to_return(:status => 200, :body => '{"lease_id":"","renewable":false,"lease_duration":0,"data":null,
          "auth":{"client_token":"'+@@expected_auth_token+'","policies":["root"],"metadata":{"username":"user"},
          "lease_duration":0,"renewable":false}}', :headers => {})

    auth_token = Vaultconf.get_auth_token(@@user, @@password, @@server)

    assert auth_token = @@expected_auth_token
  end

  def test_add_policies_to_vault
    policies_path = File.expand_path('../resources/policies', __FILE__)
    expected_url = "http://#{@@server}/v1/auth/userpass/login/"
    expected_body = "{\"password\":\"#{@@password}\"}"
    stub_request(:put, "http://localhost:8200/v1/sys/policy/reader").
        with(:body => "{\"policy\":\"Yay\"}",
             :headers => {'Accept'=>['*/*', 'application/json'], 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/json', 'Cookie'=>'token=testtoken; path=/; expires=Mon, 29 Aug 2016 17:12:21 GMT', 'User-Agent'=>['Ruby', 'VaultRuby/0.1.4 (+github.com/hashicorp/vault-ruby)']}).
        to_return(:status => 200, :body => "", :headers => {})



    Vaultconf.add_policies_to_vault(Vault, policies_path)

    assert_requested :post, expected_url,
                     :headers => {'Content-Length' => 3}, :body => expected_body,
                     :times => 1
  end
end
