require 'erb'
require 'yaml'
require 'active_support/core_ext/hash'

module Dbmanager
  module YmlParser
    extend self
    #attr_writer :config

    def config
      @config ||= yml_load(db_config_file).deep_merge(override_config)
    end

    def override_config
      File.file?(db_override_file) ? yml_load(db_override_file) : {}
    end

    def reload_config
      @config = nil
      config
    end

    def environments
      @environments ||= begin
        yml_envs.each_with_object(ActiveSupport::OrderedHash.new) do |arr, hash|
          hash[arr[0]] = Environment.new arr[1].merge(:name => arr[0])
        end
      end
    end

    private

    def yml_envs
      config.select do |key, value|
        value.has_key?('adapter')
      end.sort
    end

    def yml_load(path)
      YAML.load(ERB.new(File.read(path)).result) || {}
    end

    def db_config_file
      File.join Dbmanager.rails_root, 'config', 'database.yml'
    end

    def db_override_file
      File.join Dbmanager.rails_root, 'config', 'dbmanager_override.yml'
    end
  end
end
