require 'ladder/model/statement'
require 'ladder/model/graph'

module Ladder
  module RDFSource
    def initialize(*)
      Ladder::Statement.store_in(collection: Ladder::LDP.settings.repository.collection.name)
      super
    end

    def create(input, content_type, &block)
      super

      [self.graph, self.metagraph].each do |g|
        Ladder::Graph.find_or_create_by(g_to_attr(g)) unless g.empty?
      end

      self
    end

    def update(input, content_type, &block)
      super

      [self.graph, self.metagraph].each do |g|
        # TODO: if graph is empty, delete it?
        Ladder::Graph.find_or_initialize_by(g_to_attr(g)).save unless g.empty?
      end

      self
    end

    def destroy(&block)
      super

      [self.graph, self.metagraph].each do |g|
        Ladder::Graph.destroy_all(g_to_attr(g))
      end

      self
    end

    private

    def g_to_attr(g)
      RDF::Mongo::Conversion.to_mongo(g.name, :graph_name)
    end
  end
end