require 'test/unit'
require 'webmock/test_unit'
require 'vaultconf.rb'

class TestLogin < Test::Unit::TestCase
  def test_login
    # Given I have a stubbed vault server
    server = 'localhost:8200'
    user = 'mike'
    password = 'xdf32'
    expected_auth_token = 'authtoken123'

    stub_request(:post, "http://localhost:8200/v1/auth/userpass/login/#{user}").
        with(:body => "{\"password\":\"#{password}\"}").
        to_return(:status => 200, :body => '{"lease_id":"","renewable":false,"lease_duration":0,"data":null,
          "auth":{"client_token":"'+expected_auth_token+'","policies":["root"],"metadata":{"username":"user"},
          "lease_duration":0,"renewable":false}}', :headers => {})

    auth_token = Vaultconf.get_auth_token(user, password, server)

    assert auth_token = expected_auth_token
  end
end
