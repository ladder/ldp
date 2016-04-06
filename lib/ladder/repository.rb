require 'active_triples'
require 'active_triples/mongoid_strategy'

module Ladder
  class Repository
    def initialize(*args)
      @rdf_source = ActiveTriples::Resource.new(*args)
      @rdf_source.set_persistence_strategy(ActiveTriples::MongoidStrategy)
    end

    # FIXME: #query should query the datastore, not the @rdf_source
    delegate :to_a, :query, :has_graph?, to: :'@rdf_source'

    # def clear!
    # def supports?(feature)
    # def insert_statement(statement)
    # def delete_statement(statement)
    # def durable?; true; end
    # def empty?
    # def count
    # def clear_statements
    # def has_statement?(statement)
    # def each_statement(&block)
    # alias_method :each, :each_statement
    # def has_graph?(value)

    # def insert
    # def first
    delegate :insert, :first, to: :graph

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

    def clear!
      @rdf_source.destroy!
    end

    def supports?(feature)
      # RDFSource uses #rdf_subject as a sort of #graph_name
      return true if :graph_name == feature

      graph.supports? feature
    end

    def transaction(mutable: true, &block)
      # FIXME / TODO
      # RDF::Graph doesn't support #transaction in 1.99, only 2.0.0
      repo = RDF::Repository.new
      repo.transaction(mutable: true, &block) # NB: this is the slowest part of persistence

      graph << repo

      # Assign a graph name if the RDFSource doesn't have one
      @rdf_source.set_subject! graph.name unless @rdf_source.uri?
      @rdf_source.persist!

      graph
    end

  end
end
