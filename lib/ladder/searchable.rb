require 'elasticsearch/model'
require 'ladder/searchable/background'

require 'pry'

module Ladder
  module Searchable
    extend ActiveSupport::Concern

#    autoload :Graph, 'ladder/searchable/graph'
#    autoload :File,  'ladder/searchable/file'

    included do
      include Elasticsearch::Model
      include Ladder::Searchable::Background

      # TODO: self-checking, not ancestors
#      include Ladder::Searchable::Graph if ancestors.include? Ladder::Graph
#      include Ladder::Searchable::File  if ancestors.include? Ladder::File
    end
  end
end