# Vaultconf
A command line tool to allow use of a yaml VPN configuration file to push this config to Skyscape

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'vaultconf'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install vaultconf
    
Require it in your ruby code using:
require 'vaultconf'

## Usage
Run with option --help to show command line help.

Example command line with gem installed, to add policies to your vault server:
```bash
vaultconf policies -c test/resources/policies -u user -p password -a http://localhost:8200
```
And to add users with associated policies to your vault server:
```bash
vaultconf users -c test/resources/users/users.yaml -u user -p password -a http://localhost:8200
```

Example command line if you have cloned the repository without installing as a gem:
bundle exec ./bin/vaultconf policies -c test/resources/policies -u user -p password -a http://localhost:8200

Example policies directory structure is provided in test/resources/policies.
Example users yaml structure is provided in test/resources/users/users/yaml

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/UKHomeOffice/vcloud_ipec-vpn/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
