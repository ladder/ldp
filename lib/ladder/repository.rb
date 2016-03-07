require 'active_triples'
require 'active_triples/mongoid_strategy'

module Ladder
  class Repository
    def initialize(*args)
      @rdf_source = ActiveTriples::Resource.new(*args)
      @rdf_source.set_persistence_strategy(ActiveTriples::MongoidStrategy)
    end

    delegate :to_a, :query, :has_graph?, to: :'@rdf_source'

    def graph
      @rdf_source.send(:graph)
    end

    #####
    # FIXME: TEMPORARY FOR INTERFACE BUILDING
    #####
    def method_missing(symbol, *args, &block)
      binding.pry
    end
    #
    #####

    def supports?(feature)
      # RDFSource uses #rdf_subject as a sort of #graph_name
      return true if :graph_name == feature

      graph.supports? feature
    end

    def transaction(mutable: true, &block)
      graph.transaction(mutable: true, &block)

      # Assign a graph name if the RDFSource doesn't have one
      @rdf_source.set_subject! graph.name unless @rdf_source.uri?
      @rdf_source.persist!

      graph
    end

  end
end
