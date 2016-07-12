require 'ladder/graphable'
require 'ladder/searchable/graph'

module Ladder
  class Graph
    include Ladder::Graphable
    include Ladder::Searchable::Graph
  end
end
