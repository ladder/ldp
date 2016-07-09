require 'mongoid'
require 'ladder/searchable/graph'

module Ladder
  class Graph
    include Mongoid::Document
    include Ladder::Searchable::Graph

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
      graph = RDF::Graph.new(graph_name: self.c, data: RDF::Repository.new) # (if self.ct == :u)
      statements.each { |s| graph << RDF::Statement.from_mongo(s)}
      graph
    end
  end
end

###
# This will store metagraphs in the same collection, but with a _type field
# Documents are indexed in a separate index 'ladder-metagraphs'
module Ladder
  class MetaGraph < Ladder::Graph
  end
end