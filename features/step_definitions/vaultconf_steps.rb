require 'curb'
require 'vault'
require 'json'

Given(/^I have a vault server running$/) do
  setup_vault_server
  address = 'http://127.0.0.1:8200'
  username = 'user'
  password = 'password'
  Vault.address = address
  Vault.auth.userpass(username, password)
end


When(/^I do "vaultconf policies \-c test\/resources\/policies \-u user \-p password \-a http:\/\/localhost:8200 --nokube"$/) do
  `bundle exec bin/vaultconf policies test/resources/policies -u user -p password -a http://localhost:8200 -c test/resources/policies --nokube`
end

When(/^I do "vaultconf users \-c test\/resources\/users\/users\.yaml \-u user \-p password \-a http:\/\/localhost:8200 --nokube"$/) do
  @output = `bundle exec bin/vaultconf users -u user -p password -a http://localhost:8200 -c test/resources/users/users.yaml --nokube`
end

Then(/^I should be able to see these policies in vault$/) do
  policies = Vault.sys.policies
  expect(policies.include?('dev_myproject_writer')).to eq(true)
  expect(policies.include?('dev_myproject_reader')).to eq(true)
  expect(policies.include?('uat_myproject_reader')).to eq(true)
  expect(policies.include?('uat_myproject_reader')).to eq(true)
  expect(policies.include?('uat_anotherproject_apolicy')).to eq(true)
  writerPolicy = Vault.sys.policy('dev_myproject_writer')
  readerPolicy = Vault.sys.policy('dev_myproject_reader')
  expect(writerPolicy.rules.gsub(/\s+/, "")).to eq('{"path":{"secret/*":{"policy":"write"}}}')
  expect(readerPolicy.rules.gsub(/\s+/, "")).to eq('{"path":{"secret/*":{"policy":"read"}}}')
end

def setup_vault_server
  @vault_server = fork do
    exec 'vault server -dev'
  end
  sleep 2
  `vault auth-enable -address=http://localhost:8200 userpass`
  `vault write -address=http://localhost:8200 auth/userpass/users/user password=password policies=root`
  `vault mount -path=dev_myproject_aws  -address=http://localhost:8200 aws`
  `vault mount -address=http://localhost:8200 pki`
end


And(/^vault already contains policies$/) do
  `bundle exec bin/vaultconf policies -u user -p password -a http://localhost:8200 -c test/resources/policies`
end


Then(/^I should get a json output of the users and their generated passwords$/) do
  jsonOutput =  JSON.parse(@output)
  expect(jsonOutput.include?('dev_myproject_MrWrite')).to eq(true)
  expect(jsonOutput.include?('dev_myproject_MrRead')).to eq(true)
  expect(jsonOutput.include?('uat_myproject_MrRead')).to eq(true)
  expect(jsonOutput.include?('uat_myproject_MrRead')).to eq(true)
  expect(jsonOutput.include?('uat_anotherproject_AnotherUser')).to eq(true)
end

And(/^I should be able to see the users and their associated policies in vault$/) do
  MrWrite = Vault.logical.read('auth/userpass/users/dev_myproject_MrWrite')
  MrRead = Vault.logical.read('auth/userpass/users/dev_myproject_MrRead')
  AnotherUser = Vault.logical.read('auth/userpass/users/uat_anotherproject_AnotherUser')

  expect(MrWrite.values[3][:policies]).to eq('dev_myproject_writer,dev_myproject_reader')
  expect(MrRead.values[3][:policies]).to eq('dev_myproject_reader')
  expect(AnotherUser.values[3][:policies]).to eq('uat_anotherproject_apolicy')
end


And(/^I do "vaultconf secrets \-c test\/resources\/secrets \-u user \-p password \-a http:\/\/localhost:8200 \-\-nokube"$/) do
  `bundle exec bin/vaultconf secrets -c test/resources/secrets -u user -p password -a http://localhost:8200 --nokube`
end

Then(/^I should be able to see these secrets in vault$/) do
  all_powerful = Vault.logical.read('dev_myproject_aws/roles/all-powerful')
  mini_role = Vault.logical.read('dev_myproject_aws/roles/mini-role')
  example_dot_com = Vault.logical.read('pki/roles/example-dot-com')

  expect(all_powerful.values[3][:policy]).to eq('{"Version":"2012-10-17","Statement":{"Effect":"Allow","Action":"iam:*","Resource":"*"}}')
  expect(mini_role.values[3][:policy]).to eq('{"Version":"2012-10-17","Statement":{"Effect":"Allow","Action":"iam:just-this-one","Resource":"*"}}')
  expect(example_dot_com.values[3][:allowed_base_domain]).to eq('example.com')
  expect(example_dot_com.values[3][:allow_subdomains]).to eq(true)
  expect(example_dot_com.values[3][:max_ttl]).to eq('72h')
end