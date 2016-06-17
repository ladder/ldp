require 'mongoid'
require 'ladder/searchable/graph'

module Ladder
  class Statement
    include Mongoid::Document

    # Use the same field names as RDF::Mongo::Conversion
    %i(s st p pt o ot ol c ct).each { |key| field key }

    index({s: 1})
    index({p: 1})
    index({o: 'hashed'})
    index({c: 1})
    index({s: 1, p: 1})
    index({s: 1, p: 1, o: 1})
  end

  class Graph
    include Mongoid::Document

    include Ladder::Searchable::Graph # TODO: don't index metagraphs?
    index_for_search :as_jsonld       # TODO: fix ES problems with #as_flattened_jsonld

    field :c
    field :ct, default: :default
    field :statements, type: Array

    index({c: 1})
    index({ct: 1})

    store_in collection: 'graphs'

    before_save { project_graph if changed? }

    def project_graph
      self.statements = Ladder::Statement.where({c: self.c, ct: self.ct}).map { |s| s.attributes }
    end

    def to_rdf
      graph = RDF::Graph.new # name: self.c (if self.ct == :u)
      statements.each { |s| graph << RDF::Statement.from_mongo(s)}
      graph
    end
  end
end

module RDF::LDP
  class RDFSource
    def initialize(subject_uri, data = RDF::Repository.new)
      super

      # Configuration settings for Mongoid
      Mongoid.load_configuration({ clients: { default: { uri: Ladder::LDP.settings.uri } } }) unless Mongoid.configured?

      data = Ladder::LDP.settings.repository
      Ladder::Statement.store_in(database: data.collection.database.name, collection: data.collection.name)
    end

    def create(input, content_type, &block)
      super do |transaction|
        statements = parse_graph(input, content_type)
        transaction.insert(statements)
        yield transaction if block_given?
      end

      [self.graph, self.metagraph].each do |g|
        Ladder::Graph.find_or_create_by(RDF::Mongo::Conversion.to_mongo(g.name, :graph_name)) unless g.empty?
      end

      self
    end

    def update(input, content_type, &block)
      super do |transaction|
        transaction.delete(RDF::Statement(nil, nil, nil, graph_name: subject_uri))
        transaction.insert parse_graph(input, content_type)
        yield transaction if block_given?
      end

      [self.graph, self.metagraph].each do |g|
        Ladder::Graph.where(RDF::Mongo::Conversion.to_mongo(g.name, :graph_name)).first_or_initialize.save unless g.empty?
      end

      self
    end

    def destroy(&block)
      super do |tx|
        tx.delete(RDF::Statement(nil, nil, nil, graph_name: subject_uri))
      end

      [self.graph, self.metagraph].each do |g|
        Ladder::Graph.where(RDF::Mongo::Conversion.to_mongo(g.name, :graph_name)).destroy
      end

      self
    end
  end
end