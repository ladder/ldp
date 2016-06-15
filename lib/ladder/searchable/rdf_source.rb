require 'json/ld'

module Ladder
  module Searchable
    module RDFSource
      extend ActiveSupport::Concern

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
      # Return a JSON-LD representation for the RDFSource
      #
      # @see ActiveTriples::RDFSource#dump
      #
      # @param [Hash] opts options to pass to ActiveTriples
      # @option opts [Boolean] :related whether to include related RDFSources (default: false)
      # @return [Hash] a serialized JSON-LD version of the RDFSource
      def as_jsonld
        JSON.parse self.to_rdf.dump(:jsonld, standard_prefixes: true)
      end

      ##
      # Use a flattened form of JSON-LD to avoid assigning weird attributes (eg. 'dc:title')
      #
      # @return [Hash] a serialized JSON-LD version of the RDFSource
      def as_framed_jsonld
        json = JSON.parse(to_rdf.dump(:jsonld, standard_prefixes: true, useNativeTypes: true))
        JSON::LD::API.flatten(json, json['@context'], rename_bnodes: false)
      end
    end
  end
end
