# LDP
require 'rack/ldp'
require 'sinatra/base'

# for debugging
require 'pry'

# Persistence
require 'rdf/mongo'

require 'ladder/rdf_source'
require 'ladder/non_rdf_source'

class RDF::Ladder < Sinatra::Base
  use Rack::Lint
  use Rack::LDP::ContentNegotiation
  use Rack::LDP::Errors
  use Rack::LDP::Responses
  use Rack::ConditionalGet
  use Rack::LDP::Requests

  # Ladder interaction models
  RDF::LDP::InteractionModel.register(Ladder::RDFSource,    for: RDF::Vocab::LDP.RDFSource, default: true)
  RDF::LDP::InteractionModel.register(Ladder::NonRDFSource, for: RDF::Vocab::LDP.NonRDFSource)

  # Set defaults in case user has not configured values
  configure do
    set :uri, 'mongodb://localhost:27017/ladder'
    set :repository, RDF::Mongo::Repository.new(uri: uri)
  end

  get '/*' do
    RDF::LDP::Container.new(RDF::URI(request.url), settings.repository)
      .create(StringIO.new, 'text/turtle') if settings.repository.empty?
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
