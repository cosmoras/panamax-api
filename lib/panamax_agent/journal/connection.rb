require 'faraday'
require 'panamax_agent/middleware/response/listify_json'

module PanamaxAgent
  module Journal
    module Connection

      def connection
        Faraday.new(connection_options) do |faraday|
          faraday.request :json
          faraday.response :json
          faraday.response :listify_json
          faraday.adapter adapter
        end
      end

      private

      def connection_options
        {
          url: journal_api_url,
          ssl: ssl_options,
          proxy: proxy
        }
      end

    end
  end
end
