require 'vaultconf/version'
require 'yaml'
require 'base64'


module Kubernetes
  class KubernetesController
    def initialize(kube_service)
      @kube_service = kube_service
    end

    def add_logins_to_kubernetes(logins)
      logins.each do |login|
        username = login[:username]
        password = login[:password]
        namespace = login[:namespace].gsub('_', '-') # Kubernetes doesn't allow underscores in namespaces. Vault doesn't allow dashes for secret names, hence this substitution
        secret_name = username + '-vault'
        secretYaml = create_secret_yaml(secret_name, username, password)
        if secret_exists(secret_name, namespace)
          @kube_service.delete_secret(secret_name, namespace)
        end
        @kube_service.write_secret(secretYaml, namespace)
      end
    end

    def create_secret_yaml(secret_name, username, password)
      secret_yaml = {'apiVersion' => 'v1',
                     'kind' => 'Secret',
                     'metadata' => {
                         'name' => secret_name
                     },
                     'data' => {
                         'login' => Base64.encode64("{username:#{username},password:#{password}}"),
                     }
      }.to_yaml

      return secret_yaml
    end
  end


  # KubeService handles all interactions with kubernetes API, allowing easy mocking for tests
  class KubernetesService
    # TODO: Swap to ruby SDK for kubernetes
    def get_user_secrets(namespace)
      `kubectl --namespace=#{namespace} get secrets | grep vault | cut -f1 -d " "`.split("\n").map { |u| u.chomp "-vault" }
    end

    def write_secret(secretYaml, namespace)
      File.open('/tmp/secret.yaml', 'w') { |f| f.write secretYaml }
      result = `kubectl create -f /tmp/secret.yaml --namespace=#{namespace}`
      FileUtils.rm('/tmp/secret.yaml')
      if result == ''
        Kernel.abort("Please see the error returned from kubernetes above. Aborting secret creation.")
      end
    end

    def secret_exists(secret_name, namespace)
      secrets = `kubectl get secrets --namespace=#{namespace}`
      return secrets.include?(secret_name)
    end

    def delete_secret(secret_name, namespace)
      `kubectl delete secrets/#{secret_name} --namespace=#{namespace}`
    end
  end
end







