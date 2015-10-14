# Vaultconf
A command line tool to allow mass configuration updates in vault with support included for kubernetes. Functions include:
- update of policies in vault
- update of users in Vault

## Installation
This tool has not yet been setup as a Ruby gem, though it would be easy to do so. Instead we recommend running using docker to ensure no dependency issues:

e.g. docker run --net=host -v policies:/policies -ti quay.io/ukhomeofficedigital/vaultconf policies -c /policies -u user -p password -a http://localhost:8200 --nokube
NB: In this example --net=host is needed as we are accessing a local vault server. This is not required for accessing remote vault servers.

## Usage
Run with option --help to show command line help.

Example usage is included in vaultconf.feature.
Example policies directory structure is provided in test/resources/policies.
Example users yaml structure is provided in test/resources/users/users/yaml

In order to not need to define password in the command line vaultconf can read login details from a file called "login" in the .vaultconf directory in your home directory. The format for this file is as follows:
``` yaml
---
username: myusername
password: mypassword
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/UKHomeOffice/vaultconf/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
