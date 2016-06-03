require 'ladder/rdf_source'
require 'ladder/non_rdf_source'

module RDF::LDP
  class Resource
    def self.find(uri, data)
      graph = RDF::Graph.new(graph_name: metagraph_name(uri), data: data)
      raise NotFound if graph.empty?

      # FIXME: Monkey-patch interaction models until we have a better solution
      models = INTERACTION_MODELS.merge({RDF::LDP::RDFSource.to_uri => Ladder::RDFSource,
                                         RDF::LDP::NonRDFSource.to_uri => Ladder::NonRDFSource})

      rdf_class = graph.query([uri, RDF.type, :o]).first
      klass = models[rdf_class.object] if rdf_class
      klass ||= Ladder::RDFSource

      klass.new(uri, data)
    end
  end
end
