require 'test/unit'
require 'webmock/test_unit'
require 'vault'
require 'kubernetes'
require 'yaml'
require 'mocha/test_unit'

class TestKubernetes < Test::Unit::TestCase
  def test_create_secret_yaml
    username = 'testUser'
    password = 'testPassword'
    kube_service = mock
    kube_controller = Kubernetes::KubernetesController.new(kube_service)
    generated_yaml = kube_controller.create_secret_yaml(username + '_vault', username, password)
    expected_yaml = {'apiVersion' => 'v1',
                     'kind' => 'Secret',
                     'metadata' => {
                         'name' => 'testUser_vault'
                     },
                     'data' => {
                         'login' => 'e3VzZXJuYW1lOnRlc3RVc2VyLHBhc3N3b3JkOnRlc3RQYXNzd29yZH0=',
                     }
    }.to_yaml

    # TODO: Figure out why the 2 versions aren't the same without removing misc chars
    assert_equal(remove_misc_chars(expected_yaml), remove_misc_chars(generated_yaml))
  end

  def remove_misc_chars(str)
    str.gsub!(/\n/, '')
    str.gsub!(' ', '')
    str.gsub!('|', '')
    return str
  end
end
