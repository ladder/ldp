require 'rdf/mongoid'

module RDF::LDP
  class RDFSource < Resource
    def initialize(subject_uri, data = Ladder::LDP.settings.repository)

      # FIXME: check for proper repository type
      if data.respond_to? :collection
        RDF::Mongoid::Statement.store_in(database: data.collection.database.name, collection: data.collection.name)
      end

      super
    end

    def create(input, content_type, &block)
      statements = parse_graph(input, content_type)

      super do |transaction|
        transaction.insert(statements)
        yield transaction if block_given?
      end

      [self.graph, self.metagraph].each do |g|
        RDF::Mongoid::Graph.find_or_create_by(RDF::Mongo::Conversion.to_mongo(g.name, :graph_name)) unless g.empty?
      end

      self
    end

    def update(input, content_type, &block)
      statements = parse_graph(input, content_type)

      super do |transaction|
        transaction.delete(RDF::Statement(nil, nil, nil, graph_name: subject_uri))
        transaction.insert statements
        yield transaction if block_given?
      end

      [self.graph, self.metagraph].each do |g|
        RDF::Mongoid::Graph.where(RDF::Mongo::Conversion.to_mongo(g.name, :graph_name)).first_or_initialize.save unless g.empty?
      end

      self
    end

    def destroy(&block)
      super do |tx|
        tx.delete(RDF::Statement(nil, nil, nil, graph_name: subject_uri))
      end

      [self.graph, self.metagraph].each do |g|
        RDF::Mongoid::Graph.where(RDF::Mongo::Conversion.to_mongo(g.name, :graph_name)).destroy
      end

      self
    end
  end
end