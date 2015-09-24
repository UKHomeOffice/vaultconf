require 'test/unit'
require 'webmock/test_unit'
require 'vaultconf.rb'
require 'vault'
require 'mocha/test_unit'

class TestVault < Test::Unit::TestCase
  def setup
    @@server = 'localhost:8200'
    @@user = 'mike'
    @@password = 'xdf32'
    Vault.address = "http://#{@@server}"
    Vault.token = 'testtoken'
    @@mock_kube_service = mock
    @@vault = Vaultconf::Vaultconf.new(Vault, @@mock_kube_service)
  end

  def test_login
    expected_auth_token = 'authtoken123'
    stub_request(:post, "http://#{@@server}/v1/auth/userpass/login/#{@@user}").
        with(:body => "{\"password\":\"#{@@password}\"}").
        to_return(:status => 200, :body => '{"lease_id":"","renewable":false,"lease_duration":0,"data":null,
          "auth":{"client_token":"'+expected_auth_token+'","policies":["root"],"metadata":{"username":"user"},
          "lease_duration":0,"renewable":false}}', :headers => {})

    auth_token = Vaultconf::Vaultconf.get_auth_token(@@user, @@password, @@server)

    assert auth_token == expected_auth_token
  end

  def test_reconcile_policies_to_vault
    # Given configuration containing new policies
    policies_path = File.expand_path('../resources/simple_policies', __FILE__)
    old_policy_name = 'old_policy'

    # And that there are 2 existing policies - root, and an old policy that should be deleted
    read_all_policies_stub = stub_request(:get, "http://#{@@server}/v1/sys/policy").
        to_return(:status => 200, :body => "{\"policies\":[\"#{old_policy_name}\",\"root\"]} ", :headers => {'content_type' => 'application/json'})

    delete_policy_stub = stub_request(:delete, "http://#{@@server}/#{old_policy_name}").
        to_return(:status => 200, :body => "", :headers => {})


    reader_policy_stub = stub_request(:put, "http://#{@@server}/v1/sys/policy/dev_myproject_reader").
        to_return(:status => 200, :body => "", :headers => {})

    writer_policy_stub = stub_request(:put, "http://#{@@server}/v1/sys/policy/dev_myproject_writer").
        to_return(:status => 200, :body => "", :headers => {})

    # When I reconcile policies to vault
    @@vault.reconcile_policies_to_vault(policies_path)

    # Then the new policies should be added
    assert_requested(writer_policy_stub)
    assert_requested(reader_policy_stub)

    # And the old policy should be deleted
    assert_requested(delete_policy_stub)
  end

  def test_reconcile_users_to_vault
    users_path = File.expand_path('../resources/simple_users/users.yaml', __FILE__)
    old_user_name = 'old_user'
    namespace = 'dev'

    @@mock_kube_service.expects(:get_user_secrets).with('dev').returns(["#{namespace}-#{old_user_name}"])

    user_request_stub_writer = stub_request(:put, "http://#{@@server}/v1/auth/userpass/users/#{namespace}_MrWrite").
        with(:body => /{\"password\":\".*\",\"policies\":\"writer,reader\"}/).
        to_return(:status => 200, :body => "", :headers => {})

    user_request_stub_reader = stub_request(:put, "http://#{@@server}/v1/auth/userpass/users/#{namespace}_MrRead").
        with(:body => /{\"password\":\".*\",\"policies\":\"reader\"}/).
        to_return(:status => 200, :body => "", :headers => {})

    user_delete_stub = stub_request(:delete, "http://#{@@server}/v1/auth/userpass/users/#{namespace}_#{old_user_name}").
        to_return(:status => 200, :body => "", :headers => {})

    @@mock_kube_service.expects(:delete_secret).with("#{namespace}-#{old_user_name}" + '-vault', 'dev')

    @@vault.reconcile_users_to_vault(users_path, true)
    assert_requested(user_delete_stub)
    assert_requested(user_request_stub_writer)
    assert_requested(user_request_stub_reader)

  end

end
