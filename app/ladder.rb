require 'rack/ldp'
require 'sinatra/base'
require 'rdf/mongo'
require 'mongoid'

# for debugging
require 'pry'

# require_relative '../lib/ladder/rdf_source'
# require_relative '../lib/ladder/non_rdf_source'

module Ladder
  class LDP < Sinatra::Base

    use Rack::LDP::ContentNegotiation
    use Rack::LDP::Errors
    use Rack::LDP::Responses
    use Rack::ConditionalGet
    use Rack::LDP::Requests

    # Set defaults in case user has not configured values
    configure do
      Mongo::Logger.level = Logger::DEBUG

      # Use a class that implements the RDF::Repository interface
      set :uri, 'mongodb://localhost:27017/ladder'
      set :repository, RDF::Mongo::Repository.new(uri: uri)

      # Configuration settings for Mongoid
      Mongoid.load_configuration({ clients: { default: { uri: uri } } })
    end

    get '/*' do
      RDF::LDP::Container.new(RDF::URI(request.url), settings.repository)
        .create('', 'text/turtle') if settings.repository.empty?
      RDF::LDP::Resource.find(RDF::URI(request.url), settings.repository)
    end

    patch '/*' do
      RDF::LDP::Resource.find(RDF::URI(request.url), settings.repository)
    end

    post '/*' do
      RDF::LDP::Resource.find(RDF::URI(request.url), settings.repository)
    end

    put '/*' do
      begin
        RDF::LDP::Resource.find(RDF::URI(request.url), settings.repository)
      rescue RDF::LDP::NotFound
        model = request.env.fetch('HTTP_LINK', '')
        RDF::LDP::Resource.interaction_model(model)
          .new(RDF::URI(request.url), settings.repository)
      end
    end

    options '/*' do
      RDF::LDP::Resource.find(RDF::URI(request.url), settings.repository)
    end

    head '/*' do
      RDF::LDP::Resource.find(RDF::URI(request.url), settings.repository)
    end

    delete '/*' do
      RDF::LDP::Resource.find(RDF::URI(request.url), settings.repository)
    end

    run! if app_file == $0
  end
end
