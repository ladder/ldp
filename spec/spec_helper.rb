require "bundler/setup"
require 'rdf/isomorphic'
require 'linkeddata'
require 'rdf/ldp'
require 'rdf/spec'
require 'rdf/spec/matchers'

require 'pry' # for debugging

require_relative '../lib/ladder/rdf_source.rb'
Elasticsearch::Client.new.indices.delete(index: '_all')
require 'mongo'
Mongo::Client.new('mongodb://localhost:27017/ladder').database.drop

Dir['./spec/support/**/*.rb'].each { |f| require f }

RSpec.configure do |config|
  config.include(RDF::Spec::Matchers)
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  config.exclusion_filter = {:ruby => lambda { |version|
    RUBY_VERSION.to_s !~ /^#{version}/
  }}
end

def fixture_path(filename)
  File.join(File.dirname(__FILE__), 'data', filename)
end

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8
