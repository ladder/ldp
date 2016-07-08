require 'mongoid'
require 'ladder/searchable/graph'

module Ladder
  class Graph
    include Mongoid::Document
    include Ladder::Searchable::Graph # TODO: don't index metagraphs?

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