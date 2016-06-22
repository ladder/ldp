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
        Ladder::Graph.find_or_create_by(RDF::Mongo::Conversion.to_mongo(g.name, :graph_name)) unless g.empty?
      end

      self
    end

    def update(input, content_type, &block)
      super

      [self.graph, self.metagraph].each do |g|
        Ladder::Graph.where(RDF::Mongo::Conversion.to_mongo(g.name, :graph_name)).first_or_initialize.save unless g.empty?
      end

      self
    end

    def destroy(&block)
      super

      [self.graph, self.metagraph].each do |g|
        Ladder::Graph.where(RDF::Mongo::Conversion.to_mongo(g.name, :graph_name)).destroy
      end

      self
    end
  end
end