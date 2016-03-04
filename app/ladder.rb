require 'pry' # for debugging

require 'rack/ldp'
require 'sinatra/base'
require 'active_triples/mongoid_strategy'

require_relative '../lib/ladder/non_rdf_source'
require_relative '../lib/ladder/rdf_source'

class Ladder < Sinatra::Base

  use Rack::LDP::ContentNegotiation
  use Rack::LDP::Errors
  use Rack::LDP::Responses
  use Rack::ConditionalGet
  use Rack::LDP::Requests

  # Set defaults in case user has not configured values
  configure do
    # TODO: we're not actually going to use a repository
    # will have to modify RDFSource (or Resource)
    set :repository, RDF::Repository.new

    options = { clients: { default: { database: 'ladder', hosts: ['localhost:27017'] } } }
    Mongoid.load_configuration(options)
    Mongo::Logger.logger.level = Logger::DEBUG
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