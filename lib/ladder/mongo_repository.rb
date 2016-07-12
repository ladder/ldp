require 'ladder/model/statement'
require 'ladder/model/graph'

module Ladder
  module MongoRepository
    def clear!
      Ladder::Graph.delete_all
      super
    end
  end
end