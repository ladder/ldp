shared_examples 'a Searchable RDFSource' do
  subject { described_class.new(uri, repo) }

  let(:uri) { RDF::URI 'http://example.org/moomin' }
  let(:repo) { Ladder::LDP.settings.repository }
  let(:index) { Elasticsearch::Model.client.indices }

  describe '#create' do
=begin
    before do
      repo.clear!
      index.delete index: '_all'
    end
=end
    let(:graph) { RDF::Graph.new }
    let(:content_type) { 'text/turtle' }

    it 'does not exist in index when graph is empty' do
      begin; subject.create(graph.dump(:ttl), content_type); rescue; end

      index.flush
      results = Ladder::Graph.search('*')
      expect(results).to be_empty
    end

    it 'exists in the index' do
      graph << RDF::Statement(subject.subject_uri, RDF::Vocab::DC.isPartOf, RDF::URI('#moomintroll'))
      subject.create(graph.dump(:ttl), 'text/turtle')

      index.flush
      results = Ladder::Graph.search('moomintroll')
      expect(results.count).to eq 1
    end

    xit 'is a correct serialization' do
      expect(results.first._source.to_hash).to eq subject.as_jsonld
    end
  end

=begin
  describe '#update' do
    let(:statement) do
      RDF::Statement(subject.subject_uri, RDF::Vocab::DC.title, 'kometen')
    end

    let(:graph) { RDF::Graph.new << statement }
    let(:content_type) { 'text/turtle' }

    shared_examples 'updating rdf_sources' do
      before do
        subject.update(graph.dump(:ttl), content_type)
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

    context 'when it exists' do
      before { subject.create('', 'application/n-triples') }

      include_examples 'updating rdf_sources'
    end
  end
=end

  describe '#destroy' do
    before do
      subject.destroy
      index.flush
    end

    it 'does not exist in the index' do
      results = Ladder::Graph.search('moomintroll')
      expect(results).to be_empty
    end
  end
end