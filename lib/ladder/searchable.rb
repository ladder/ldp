require 'active_support/concern'
require 'elasticsearch/model'
require 'elasticsearch/model/callbacks'
require 'active_job'

require 'json/ld'
require 'rdf/turtle'

require 'pry'

module Ladder
  module Searchable
    module Background
      extend ActiveSupport::Concern

      included do
        include GlobalID::Identification

        GlobalID.app = 'Ladder'

        after_create   { enqueue :index }
        after_update   { enqueue :update }
        before_destroy { enqueue :delete }
      end

      private

      ##
      # Queue an index operation for asynchronous execution
      #
      # @param [Symbol] operation the kind of operation to perform: index, delete, update
      # @return [void]
      def enqueue(operation)
        Indexer.set(queue: self.class.name.underscore.pluralize).perform_later(operation.to_s, self)
      end

      class Indexer < ActiveJob::Base
        queue_as :elasticsearch

        ##
        # Perform a queued index operation
        #
        # @param [String] operation the kind of operation to perform: index, delete, update
        # @param [Ladder::Resource, Ladder::File] model the object instance to modify in the index
        # @return [void]
        def perform(operation, model)
          case operation
          when 'index' then model.__elasticsearch__.index_document
          when 'update' then model.__elasticsearch__.update_document
          when 'delete' then model.__elasticsearch__.delete_document
          end
        end
      end
    end
  end
end

module Ladder
  module Searchable
    module Resource
      extend ActiveSupport::Concern

      module ClassMethods
        ##
        # Specify type of serialization to use for indexing;
        # if a block is provided, it is expected to return a Hash
        # that will be used in lieu of {#as_indexed_json} for
        # serializing the resource in the index
        #
        # @return [void]
        def index_for_search(name)
          define_method(:as_indexed_json) { |_args| self.send name } if method_defined? name
        end
      end

      ##
      # Return a JSON-LD representation for the resource
      #
      # @see ActiveTriples::Resource#dump
      #
      # @param [Hash] opts options to pass to ActiveTriples
      # @option opts [Boolean] :related whether to include related resources (default: false)
      # @return [Hash] a serialized JSON-LD version of the resource
      def as_jsonld
        JSON.parse self.to_rdf.dump(:jsonld, standard_prefixes: true)
      end

      ##
      # Use a flattened form of JSON-LD to avoid assigning weird attributes (eg. 'dc:title')
      #
      # @return [Hash] a serialized JSON-LD version of the resource
      def as_framed_jsonld
        json = JSON.parse(to_rdf.dump(:jsonld, standard_prefixes: true, useNativeTypes: true))
        JSON::LD::API.flatten(json, json['@context'], rename_bnodes: false)
      end
    end
  end
end

module Ladder
  module Searchable
    extend ActiveSupport::Concern

    included do
      include Elasticsearch::Model
      include Elasticsearch::Model::Adapter::Mongoid

      include Ladder::Searchable::Resource
      include Ladder::Searchable::Background
    end
  end
end