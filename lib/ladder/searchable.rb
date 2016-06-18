require 'elasticsearch/model'
require 'ladder/searchable/background'

require 'pry'

module Ladder
  module Searchable
    extend ActiveSupport::Concern

    included do
      include Elasticsearch::Model
      include Ladder::Searchable::Background
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
  end
end