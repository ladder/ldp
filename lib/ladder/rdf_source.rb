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

      Ladder::Graph.find_or_create_by(g_to_attr(graph)) unless graph.empty?
      Ladder::MetaGraph.find_or_create_by(g_to_attr(metagraph)) unless metagraph.empty?

      self
    end

    def update(input, content_type, &block)
      super

      # TODO: if graph is empty, delete it?
      Ladder::Graph.find_or_initialize_by(g_to_attr(graph)).save unless graph.empty?
      Ladder::MetaGraph.find_or_initialize_by(g_to_attr(metagraph)).save unless metagraph.empty?

      self
    end

    def destroy(&block)
      super

      Ladder::Graph.destroy_all(g_to_attr(graph))
      Ladder::MetaGraph.destroy_all(g_to_attr(metagraph))

      self
    end

    private

    def g_to_attr(g)
      RDF::Mongo::Conversion.to_mongo(g.name, :graph_name)
    end
  end
end