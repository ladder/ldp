shared_examples 'a Searchable NonRDFSource' do
  subject { described_class.new(uri, repo) }

  let(:uri) { RDF::URI 'http://example.org/moomin' }
  let(:repo) { Ladder::LDP.settings.repository }
  let(:index) { Elasticsearch::Model.client.indices }
  let(:contents) { StringIO.new('mummi') }

  before do
    repo.clear!
    index.delete index: '_all'
    Ladder::File.__elasticsearch__.create_index!
  end

  after { subject.destroy }

  describe '#create' do
    before do
      subject.create(contents, 'text/plain')
      index.flush
    end

    it 'writes the contents to index' do
      results = Ladder::File.search('mummi', fields: '*')
      expect(results.count).to eq 1

      # NB: mapper attachements (deprecated) inserts newlines
      # see: https://github.com/elastic/elasticsearch/issues/15095
      contents.rewind
      expect(results.first.fields['file.content'].map(&:chomp)).to eq contents.map(&:chomp)
    end

    it 'detects #content_type' do
      results = Ladder::File.search('mummi', fields: '*')
      expect(results.first.fields['file.content_type'].first).to include('text/plain')
    end
  end

  describe '#update' do
    before do
      subject.create(contents, 'text/plain')
      index.flush
    end

    it 'updates the contents in the index' do
      new_contents = StringIO.new('snorkmaiden')
      subject.update(new_contents, 'text/plain')
      index.flush

      results = Ladder::File.search('snorkmaiden', fields: '*')

      new_contents.rewind
      expect(results.first.fields['file.content'].map(&:chomp)).to eq new_contents.map(&:chomp)
    end

    it 'only changes the existing document' do
      results = Ladder::File.search('*')
      expect(results.count).to eq 1
    end

    it 'ignores explicit #content_type' do
      # TODO: revisit this logic
      contents.rewind
      subject.update(contents, 'text/prs.moomin')
      index.flush

      results = Ladder::File.search('mummi', fields: '*')
      expect(results.first.fields['file.content_type'].first).to include('text/plain')
    end
  end

  describe '#destroy' do
    before do
      subject.create(contents, 'text/plain')
      subject.destroy
      index.flush
    end

    it 'does not exist in the index' do
      results = Ladder::File.search('mummi')
      expect(results).to be_empty
    end
  end
end