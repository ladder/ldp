require 'rack/ldp'
require 'sinatra/base'
require 'rdf/mongo'

require 'mongoid'
require 'ladder/rdf_source'
require 'ladder/non_rdf_source'

# patch RDF::LDP classes
RDF::LDP::RDFSource.include    Ladder::RDFSource
RDF::LDP::NonRDFSource.include Ladder::NonRDFSource

# for debugging
require 'pry'

module Ladder
  class LDP < Sinatra::Base

    use Rack::LDP::ContentNegotiation
    use Rack::LDP::Errors
    use Rack::LDP::Responses
    use Rack::ConditionalGet
    use Rack::LDP::Requests

    # Set defaults in case user has not configured values
    configure do
      set :uri, 'mongodb://localhost:27017/ladder'
      set :repository, RDF::Mongo::Repository.new(uri: uri)
      set :log_level, :fatal
    end

    # Configuration settings for Mongoid
    Mongoid.load_configuration({ clients: { default: { uri: Ladder::LDP.settings.uri  } },
                                 options: { log_level: Ladder::LDP.settings.log_level } }) unless Mongoid.configured?

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
