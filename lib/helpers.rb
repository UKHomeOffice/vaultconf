require 'securerandom'

module Helpers
  def self.get_policy_name_from_path(filename)
    File.basename(filename, File.extname(filename))
  end

  def self.generate_password
    return SecureRandom.hex
  end

  def self.is_yaml_file(file_or_folder)
    extension = File.extname(file_or_folder)
    return extension == '.yaml' || extension == '.yml'
  end
end
