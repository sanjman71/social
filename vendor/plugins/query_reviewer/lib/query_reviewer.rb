# QueryReviewer
require "ostruct"
require 'erb'
require 'yaml'

module QueryReviewer
  CONFIGURATION = {}
  
  @@logger = nil
  mattr_accessor :logger
    
  def self.load_configuration
    default_config = YAML::load(ERB.new(IO.read(File.join(File.dirname(__FILE__), "..", "query_reviewer_defaults.yml"))).result)
    
    CONFIGURATION.merge!(default_config["all"] || {})
    CONFIGURATION.merge!(default_config[Rails.env || "test"] || {})
    
    app_config_file = File.join(Rails.root, "config", "query_reviewer.yml")
        
    if File.exist?(app_config_file)
      app_config = YAML.load(ERB.new(IO.read(app_config_file)).result)
      CONFIGURATION.merge!(app_config["all"] || {}) 
      CONFIGURATION.merge!(app_config[Rails.env || "test"] || {}) 
    end
    
    if enabled?
      begin
        if CONFIGURATION["log_file"] && CONFIGURATION["log_queries"]
          @@logger = Logger.new(File.join(Rails.root, CONFIGURATION["log_file"]))
          @@logger.lever = Logger::INFO
        end
        CONFIGURATION["uv"] ||= !Gem.searcher.find("uv").nil?
        if CONFIGURATION["uv"]
          require "uv"
        end
      rescue
        CONFIGURATION["uv"] ||= false    
      end
    end    
  end
  
  def self.enabled?
    CONFIGURATION["enabled"]
  end
end

QueryReviewer.load_configuration

if QueryReviewer.enabled?
  require "query_reviewer/query_warning"
  require "query_reviewer/array_extensions"
  require "query_reviewer/sql_query"
  require "query_reviewer/mysql_analyzer"
  require "query_reviewer/sql_sub_query"
  require "query_reviewer/mysql_adapter_extensions"
  require "query_reviewer/controller_extensions"
  require "query_reviewer/sql_query_collection"
end
