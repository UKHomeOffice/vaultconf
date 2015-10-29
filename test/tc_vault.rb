require 'test/unit'
require 'webmock/test_unit'
require 'vaultconf.rb'
require 'vault'
require 'mocha/test_unit'
require 'fakefs/safe'

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

  def test_reconcile_policies_to_vault
    # Given configuration containing new policies
    policies_path = File.expand_path('../resources/simple_policies', __FILE__)
    old_policy_name = 'old_policy'

    # And that there are 2 existing policies - root, and an old policy that should be deleted
    read_all_policies_stub = stub_request(:get, "http://#{@@server}/v1/sys/policy").
        to_return(:status => 200, :body => "{\"policies\":[\"#{old_policy_name}\",\"root\"]} ", :headers => {'content_type' => 'application/json'})

    delete_policy_stub = stub_request(:delete, "http://#{@@server}/v1/sys/policy/#{old_policy_name}").
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
        with(:body => /{\"password\":\".*\",\"policies\":\"dev_writer,dev_reader\"}/).
        to_return(:status => 200, :body => "", :headers => {})

    user_request_stub_reader = stub_request(:put, "http://#{@@server}/v1/auth/userpass/users/#{namespace}_MrRead").
        with(:body => /{\"password\":\".*\",\"policies\":\"dev_reader\"}/).
        to_return(:status => 200, :body => "", :headers => {})

    user_delete_stub = stub_request(:delete, "http://#{@@server}/v1/auth/userpass/users/#{namespace}_#{old_user_name}").
        to_return(:status => 200, :body => "", :headers => {})

    @@mock_kube_service.expects(:delete_secret).with("#{namespace}-#{old_user_name}" + '-vault', 'dev')

    @@vault.reconcile_users_to_vault(users_path, true)
    assert_requested(user_delete_stub)
    assert_requested(user_request_stub_writer)
    assert_requested(user_request_stub_reader)
  end

  def test_read_login_from_file
    FakeFS do
    # Given my home directory contains a .vaultconf directory containing my login details (NB: Filesystem is mocked as per fakefs)
      puts Dir.home
      FileUtils.mkdir_p("#{Dir.home}/.vaultconf")
      File.open("#{Dir.home}/.vaultconf/login", "w") {|file| file.write("---\nusername: myusername\npassword: mypassword\n")}
    # When I read login from file
      user, password = Vaultconf::Vaultconf.read_login_from_file
    # Then it captures the correct username and password
      assert_equal("mypassword", password, 'The password was not retrieved as expected')
      assert_equal("myusername", user, 'The username was not retrieved as expected')
    end
  end

  def test_add_secrets_to_vault
    secrets_path = File.expand_path('../resources/secrets', __FILE__)

    all_powerful_stub = stub_request(:put, "http://#{@@server}/v1/dev_myproject_aws/roles/all-powerful").
        with(:body => "{\"policy\":\"{\\\"Version\\\":\\\"2012-10-17\\\",\\\"Statement\\\":{\\\"Effect\\\":\\\"Allow\\\",\\\"Action\\\":\\\"iam:*\\\",\\\"Resource\\\":\\\"*\\\"}}\"}").
        to_return(:status => 200, :body => "", :headers => {})

    mini_role_stub = stub_request(:put, "http://#{@@server}/v1/dev_myproject_aws/roles/mini-role").
        with(:body => "{\"policy\":\"{\\\"Version\\\":\\\"2012-10-17\\\",\\\"Statement\\\":{\\\"Effect\\\":\\\"Allow\\\",\\\"Action\\\":\\\"iam:just-this-one\\\",\\\"Resource\\\":\\\"*\\\"}}\"}").
        to_return(:status => 200, :body => "", :headers => {})

    example_dot_com_stub = stub_request(:put, "http://#{@@server}/v1/pki/roles/example-dot-com").
        with(:body => "{\"allowed_base_domain\":\"example.com\",\"allow_subdomains\":true,\"max_ttl\":\"72h\"}").
        to_return(:status => 200, :body => "", :headers => {})

    @@vault.add_secrets_to_vault(secrets_path)

    assert_requested(all_powerful_stub)
    assert_requested(mini_role_stub)
    assert_requested(example_dot_com_stub)
  end

  def test_find_secret_files
    secrets_path = File.expand_path('../resources/secrets', __FILE__)
    secret_files = @@vault.find_secret_files(secrets_path)

    assert_includes(secret_files, File.expand_path('../resources/secrets/dev_myproject/aws_backend/all-powerful.yaml',__FILE__))
    assert_includes(secret_files, File.expand_path('../resources/secrets/dev_myproject/aws_backend/mini-role.yaml',__FILE__))
    assert_includes(secret_files, File.expand_path('../resources/secrets/dev_myproject/ca_backend/example-dot-com.yaml',__FILE__))
  end
end
