require 'aruba/cucumber'
require 'methadone/cucumber'
require 'vault'

ENV['PATH'] = "#{File.expand_path(File.dirname(__FILE__) + '/../../bin')}#{File::PATH_SEPARATOR}#{ENV['PATH']}"
LIB_DIR = File.join(File.expand_path(File.dirname(__FILE__)),'..','..','lib')

Before do
  # Using "announce" causes massive warnings on 1.9.2
  @puts = true
  @original_rubylib = ENV['RUBYLIB']
  ENV['RUBYLIB'] = LIB_DIR + File::PATH_SEPARATOR + ENV['RUBYLIB'].to_s
  setup_vault_server

end

def setup_vault_server
  @vault_server = fork do
    exec 'vault server -dev'
  end
  sleep 2
  `vault auth-enable -address=http://localhost:8200 userpass`
  `vault write -address=http://localhost:8200 auth/userpass/users/user password=password policies=root`
end

After do
  ENV['RUBYLIB'] = @original_rubylib
  Vault.sys.policies.select{|policy| policy != 'root'}.each { |policy| Vault.sys.delete_policy(policy) }
  puts @pid
  Process.kill 'SIGTERM', @vault_server
end

