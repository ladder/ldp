require 'ladder/index/graph'

module RDF::LDP
  class RDFSource
    def initialize(subject_uri, data = RDF::Repository.new)
      @index = ::Ladder::Index::Graph.new
      @index.create_index!
      super
    end

    def create(input, content_type, &block)
      statements = parse_graph(input, content_type)
      @index.save(statements) unless statements.empty?

      super do |transaction|
        transaction.insert(statements)
        yield transaction if block_given?
      end
    end

    def update(input, content_type, &block)
      statements = parse_graph(input, content_type)

      @index.delete(statements.graph_name.to_s, ignore: 404)
      @index.save(statements) unless statements.empty?

      super do |transaction|
        transaction.delete(RDF::Statement(nil, nil, nil, graph_name: subject_uri))
        transaction.insert statements
        yield transaction if block_given?
      end

      self
    end

    def destroy(&block)
      @index.delete(subject_uri.to_s, ignore: 404)

      super do |tx|
        tx.delete(RDF::Statement(nil, nil, nil, graph_name: subject_uri))
      end
    end
  end
end