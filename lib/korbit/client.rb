require 'json'
require 'net/http'
require_relative 'client/version'

module Korbit
  class Client

    attr :token

    def initialize(options={})
      options.symbolize_keys!
      @endpoint = options[:endpoint] || "https://api.korbit.co.kr"
      initialize_token options
    end

    def get(path, params={})
      uri = URI("#{@endpoint}#{path}")

      params= @token.attach_token params
      uri.query = params.to_query

      parse Net::HTTP.get_response(uri)
    end

    def post(path, params={})
      uri = URI("#{@endpoint}#{path}")
      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = true if @endpoint.start_with?('https://')
      http.start do |http|
        params = @token.attach_token(params) unless path.end_with?('oauth2/access_token')
        parse http.request_post(path, params.to_query)
      end
    end

    private

    def parse(response)
      JSON.parse response.body
    rescue JSON::ParserError => e
      raise BitBot::UnauthorizedError, response['warning']
    end

    def initialize_token(options)
      if options[:client_id] && options[:client_secret]
        @token = Token.new self, options
        #@token.refresh_token!
      else
        raise ArgumentError, 'Missing key and/or secret'
      end
    end

  end
end
