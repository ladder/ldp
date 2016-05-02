require 'elasticsearch/persistence'

module Ladder
  class GraphIndex
    include Elasticsearch::Persistence::Repository

    klass RDF::Graph

    def serialize(graph)
      json = JSON.parse(graph.dump(:jsonld, standard_prefixes: true))
      hash = JSON::LD::API.flatten(json, json['@context'], rename_bnodes: false)

      # FIXME: this seems a bit wonky
      hash['id'] = graph.graph_name.to_s
      hash

      # NB: for (framed) object-based indexing
      #
      # context = json['@context']
      # frame = { '@context' => context }
      # JSON::LD::API.compact(JSON::LD::API.frame(json, frame), context)
    end

    def deserialize(document)
      json = document['_source']
      statements = JSON::LD::API.toRdf(json)
      RDF::Graph.new << statements
    end
  end
end