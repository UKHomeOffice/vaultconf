require 'vaultconf/version'
require 'yaml'
require 'base64'


module Kubernetes
  def self.add_logins_to_kubernetes(logins)
    logins.each do |login|
      username = login[:username]
      password = login[:password]
      namespace = login[:namespace].gsub('_','-') # Kubernetes doesn't allow underscores in namespaces. Vault doesn't allow dashes for secret names, hence this substitution
      secret_name = username + '-vault'
      secretYaml = Kubernetes.create_secret_yaml(secret_name, username, password)
      if secret_exists(secret_name, namespace)
        `kubectl delete secrets/#{secret_name} --namespace=#{namespace}`
      end
      puts "WRITING STUFF"
      puts secret_name
      Kubernetes.write_secret(secretYaml, namespace)
    end
  end

  def self.write_secret(secretYaml, namespace)
    File.open('/tmp/secret.yaml', 'w') {|f| f.write secretYaml}
    result = `kubectl create -f /tmp/secret.yaml --namespace=#{namespace}`
    FileUtils.rm('/tmp/secret.yaml')
    if result == ''
      Kernel.abort("Please see the error returned from kubernetes above. Aborting secret creation.")
    end
  end

  def self.secret_exists(secret_name, namespace)
    secrets = `kubectl get secrets --namespace=#{namespace}`
    return secrets.include?(secret_name)
  end

  def self.create_secret_yaml(secret_name, username, password)
    secret_yaml = {'apiVersion' => 'v1',
                   'kind' => 'Secret',
                   'metadata' => {
                       'name' => secret_name
                   },
                   'data' => {
                       'username' => Base64.encode64(username),
                       'password' => Base64.encode64(password)
                   }
    }.to_yaml

    return secret_yaml
  end
end