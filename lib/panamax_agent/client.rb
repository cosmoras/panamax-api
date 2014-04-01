require 'panamax_agent/connection'
require 'panamax_agent/request'

module PanamaxAgent
  class Client

    include PanamaxAgent::Connection
    include PanamaxAgent::Request

    attr_accessor(*Configuration::VALID_OPTIONS_KEYS)
    attr_accessor :url
    attr_accessor :api_version

    def initialize(options={})
      options = PanamaxAgent.options.merge(options)
      Configuration::VALID_OPTIONS_KEYS.each do |key|
        send("#{key}=", options[key])
      end
    end

    protected

    def resource_path(resource, *parts)
      parts.unshift(resource).join('/')
    end
  end
end
