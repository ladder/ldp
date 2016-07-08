require 'elasticsearch/model'
require 'ladder/searchable/background'

module Ladder
  module Searchable
    extend ActiveSupport::Concern

    included do
      include Elasticsearch::Model
      # include Elasticsearch::Model::Callbacks
      include Ladder::Searchable::Background
    end
  end
end