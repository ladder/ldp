shared_examples 'a Searchable NonRDFSource' do
  subject { described_class.new(uri, repo) }
  let(:uri) { RDF::URI 'http://example.org/moomin' }

  let(:contents) { StringIO.new('mummi') }
  let(:repo) { Ladder::LDP.settings.repository }
  before { repo.clear! }

  after { subject.destroy }

  describe '#save' do
    before do
      subject.save
      Elasticsearch::Model.client.indices.flush
    end

    it 'should exist in the index' do
      results = subject.class.search('*')
      expect(results.count).to eq 1
      expect(results.first.id).to eq subject.id.to_s
    end

    it 'should contain full-text content' do
      results = subject.class.search 'mummi', fields: '*'
      expect(results.count).to eq 1
      expect(results.first.fields.file.first).to include 'mummi'
    end
  end

  describe '#save with update' do
    before do
      subject.save
      subject.file = contents
      subject.save
      Elasticsearch::Model.client.indices.flush
    end

    it 'should have updated full-text content' do
      results = subject.class.search 'frightening', fields: '*'
      expect(results.count).to eq 1
      expect(results.first.fields.file.first).to include 'frightening'
    end
  end

  describe '#destroy' do
    before do
      subject.save
      subject.destroy
      Elasticsearch::Model.client.indices.flush
    end

    it 'should not exist in the index' do
      results = subject.class.search('*')
      expect(results).to be_empty
    end
  end

end