require 'active_support/concern'
require 'elasticsearch/model'
require 'elasticsearch/model/callbacks'

module Ladder
  module Searchable
    extend ActiveSupport::Concern

    autoload :RDFSource, 'ladder/searchable/rdf_source'
    autoload :Background, 'ladder/searchable/background'

    included do
      include Elasticsearch::Model
      include Elasticsearch::Model::Adapter::Mongoid

      include Ladder::Searchable::RDFSource
      include Ladder::Searchable::Background
    end
  end
end