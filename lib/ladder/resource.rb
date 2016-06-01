module Ladder
  class RDFSource < RDF::LDP::RDFSource
    def initialize(subject_uri, data = nil)
      data = Ladder::LDP.settings.repository

      # FIXME: check for proper repository type
      if data.respond_to? :collection
        Ladder::Statement.store_in(database: data.collection.database.name, collection: data.collection.name)
      end
      # else what?

      super
    end

    def create(input, content_type, &block)
      super

      [self.graph, self.metagraph].each do |g|
        Ladder::Graph.find_or_create_by(RDF::Mongo::Conversion.to_mongo(g.name, :graph_name)) unless g.empty?
      end

      self
    end

    def update(input, content_type, &block);
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

module RDF::LDP
  class Resource
    def self.find(uri, data)
      graph = RDF::Graph.new(graph_name: metagraph_name(uri), data: data)
      raise NotFound if graph.empty?

      rdf_class = graph.query([uri, RDF.type, :o]).first

      models = INTERACTION_MODELS.merge(RDF::LDP::RDFSource.to_uri => Ladder::RDFSource)
      klass = models[rdf_class.object] if rdf_class

      klass ||= Ladder::RDFSource

      klass.new(uri, data)
    end
  end
end
