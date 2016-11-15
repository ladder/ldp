#require 'ladder/model/statement'
#require 'ladder/model/graph'
#require 'ladder/model/metagraph'

module Ladder
  class RDFSource < RDF::LDP::RDFSource
=begin
    def initialize(*)
      Ladder::Statement.store_in(collection: Ladder::LDP.settings.repository.collection.name)
      super
    end

    def create(input, content_type, &block)
      super

      unless graph.empty?
        Ladder::Graph.find_or_create_by(g_to_attr(graph))
        Ladder::Metagraph.find_or_create_by(g_to_attr(metagraph))
      end

      self
    end

    def update(input, content_type, &block)
      super

      if graph.empty?
        Ladder::Graph.destroy_all(g_to_attr(graph))
      else
        Ladder::Graph.find_or_initialize_by(g_to_attr(graph)).save
      end

      Ladder::Metagraph.find_or_initialize_by(g_to_attr(metagraph)).save unless metagraph.empty?

      self
    end

    def destroy(&block)
      super

      Ladder::Graph.destroy_all(g_to_attr(graph))

      # NB: we destroy metagraphs to trigger appropriate callbacks
      Ladder::Metagraph.destroy_all(g_to_attr(metagraph))

      self
    end

    private

    def g_to_attr(g)
      RDF::Mongo::Conversion.to_mongo(g.name, :graph_name)
    end
=end
  end
end