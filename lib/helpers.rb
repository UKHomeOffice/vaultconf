require 'securerandom'

module Helpers
  def self.remove_file_extension(filename)
    File.basename(filename, File.extname(filename))
  end

  def self.generate_password
    return SecureRandom.hex
  end
end