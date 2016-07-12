require 'elasticsearch/model'
require 'active_job'

module Ladder
  module Searchable
    extend ActiveSupport::Concern

    included do
      include Elasticsearch::Model
      include GlobalID::Identification

      GlobalID.app = 'Ladder'

      # Register callback hooks if we can
      if ancestors.include? ActiveSupport::Callbacks
        after_create   { enqueue :index  }
        after_update   { enqueue :update }
        before_destroy { enqueue :delete }
      end
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
      # @param [Ladder::Graph, Ladder::File] model the object instance to modify in the index
      # @return [void]
      def perform(operation, model)
        case operation
        when 'index'  then model.__elasticsearch__.index_document
        when 'update' then model.__elasticsearch__.update_document ignore: 404
        when 'delete' then model.__elasticsearch__.delete_document ignore: 404
        end
      end
    end
  end
end