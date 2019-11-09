# frozen_string_literal: true

require 'json'
require 'fileutils'

class LocalStorage
  attr_reader :location

  # @param [String] filepath
  def initialize(filepath)
    @location = File.expand_path(filepath)
    create_parent_dir
  end

  def put(object)
    File.open(location, 'w') do |f|
      f.puts serialize(object)
    end

    object
  end

  def get
    return unless exists?

    deserialize File.read(location)
  end

  private

  def create_parent_dir
    dirname = File.dirname(location)
    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
  end

  def exists?
    File.file?(location)
  end

  def serialize(object)
    JSON.generate(object)
  end

  def deserialize(string)
    JSON.parse(string, symbolize_names: true)
  end
end
