require 'securerandom'

module Helpers
  def self.get_policy_name_from_path(filename)
    File.basename(filename, File.extname(filename))
  end

  def self.generate_password
    return SecureRandom.hex
  end
end
