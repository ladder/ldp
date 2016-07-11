shared_examples 'a Searchable RDFSource' do
  subject { described_class.new(uri, repo) }

  let(:uri) { RDF::URI 'http://example.org/moomin' }
  let(:repo) { Ladder::LDP.settings.repository }
  let(:index) { Elasticsearch::Model.client.indices }

  before { repo.clear! }

  after { subject.destroy }

  describe '#create' do
    let(:graph) { RDF::Graph.new }
    let(:content_type) { 'text/turtle' }

    context 'with an empty graph' do
      before do
        begin; subject.create(graph.dump(:ttl), content_type); rescue; end
        index.flush
      end

      it 'does not exist in index' do
        results = Ladder::Graph.search('*')
        expect(results).to be_empty
      end

      it 'does not index a metagraph' do
        results = Ladder::Metagraph.search('*')
        expect(results).to be_empty
      end
    end

    context 'with data in graph' do
      before do
        graph << RDF::Statement(subject.subject_uri, RDF::Vocab::DC.isPartOf, RDF::URI('#moomintroll'))
        begin; subject.create(graph.dump(:ttl), content_type); rescue; end
        index.flush
      end

      it 'exists in the index' do
        results = Ladder::Graph.search('moomintroll')
        expect(results.count).to eq 1
      end

      it 'indexes a metagraph' do
        results = Ladder::Metagraph.search('*')
        expect(results).not_to be_empty
      end
    end

    xit 'is a correct serialization' do
      expect(results.first._source.to_hash).to eq subject.as_jsonld
    end
  end

  describe '#update' do
    # let(:subject) { described_class.new(RDF::URI('http://ex.org/m', repo)) }
    let(:statement) do
      RDF::Statement(subject.subject_uri, RDF::Vocab::DC.title, 'kometen')
    end

    let(:graph) { RDF::Graph.new << statement }
    let(:content_type) { 'text/turtle' }

    shared_examples 'updating rdf_sources' do
      before do
        subject.update(graph.dump(:ttl), content_type)
        index.flush
      end

      it 'updates the index' do
        results = Ladder::Graph.search('kometen')
        expect(results.count).to eq 1
      end

      it 'only changes the existing document' do
        results = Ladder::Graph.search('*')
        expect(results.count).to eq 1
      end
    end

    include_examples 'updating rdf_sources'

    context 'when graph is empty' do
      before do
        subject.update('', content_type)
        index.flush
      end

      it 'removes the graph from the index' do
        results = Ladder::Graph.search('kometen')
        expect(results).to be_empty
      end
    end

    context 'when it exists' do
      before do
        # FIXME: clean this up
        repo.clear!
        index.delete index: '_all'
        Ladder::Graph.__elasticsearch__.create_index!
        Ladder::Metagraph.__elasticsearch__.create_index!

        graph << RDF::Statement(subject.subject_uri, RDF::Vocab::DC.isPartOf, RDF::URI('#moomintroll'))
        begin; subject.create(graph.dump(:ttl), content_type); rescue; end
      end

      include_examples 'updating rdf_sources'

      it 'increments the version' do
        results = Ladder::Graph.search('kometen', version: true)
        expect(results.first._version).to eq 2
      end
    end
  end

  describe '#destroy' do
    let(:statement) do
      RDF::Statement(subject.subject_uri, RDF::Vocab::DC.isPartOf, RDF::URI('#moomintroll'))
    end

    let(:graph) { RDF::Graph.new << statement }
    let(:content_type) { 'text/turtle' }

    before do
      begin; subject.create(graph.dump(:ttl), content_type); rescue; end
      subject.destroy
      index.flush
    end

    it 'does not exist in the index' do
      results = Ladder::Graph.search('moomintroll')
      expect(results).to be_empty
    end
  end
end