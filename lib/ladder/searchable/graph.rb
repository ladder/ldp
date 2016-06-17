require 'ladder/searchable'
require 'json/ld'

module Ladder
  module Searchable
    module Graph
      extend ActiveSupport::Concern

      included do
        include Ladder::Searchable
      end

      module ClassMethods
        ##
        # Specify type of serialization to use for indexing;
        # if a block is provided, it is expected to return a Hash
        # that will be used in lieu of {#as_indexed_json} for
        # serializing the RDFSource in the index
        #
        # @return [void]
        def index_for_search(name)
          define_method(:as_indexed_json) { |_args| self.send name } if method_defined? name
        end
      end

      ##
      # Serialize the resource as JSON for indexing
      #
      # @see Elasticsearch::Model::Serializing#as_indexed_json
      #
      # @return [Hash] a serialized version of the resource
      def as_indexed_json(*)
        as_json(except: [:id, :_id])
      end

      ##
      # Return a JSON-LD representation for the Graph
      #
      # @see RDF::Graph#dump
      #
      # @return [Hash] a serialized JSON-LD version of the Graph
      def as_jsonld
        JSON.parse self.to_rdf.dump(:jsonld, standard_prefixes: true)
      end

      ##
      # Use a flattened form of JSON-LD to avoid assigning weird attributes (eg. 'dc:title')
      #
      # @return [Hash] a serialized JSON-LD version of the RDFSource
      def as_flattened_jsonld
        json = JSON.parse(to_rdf.dump(:jsonld, standard_prefixes: true, useNativeTypes: true))
        JSON::LD::API.flatten(json, json['@context'], rename_bnodes: false)
      end
    end
  end
end
