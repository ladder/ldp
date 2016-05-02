# @todo: make this set of examples less opinionated about #add behavior.
#   Break #add tests into another group shared between DirectContainer & 
#   IndirectContainer. This way other implementations can use these specs
#   but make different intrepretations of loose parts in the LDP spec.
shared_examples 'a DirectContainer' do
  it_behaves_like 'a Container'

  let(:uri) { RDF::URI('http://ex.org/moomin') }
  subject { described_class.new(uri) }

  let(:has_member_statement) do
    RDF::Statement(subject.subject_uri, 
                   RDF::Vocab::LDP.hasMemberRelation, 
                   RDF::Vocab::DC.hasPart)
  end

  let(:is_member_of_statement) do
    RDF::Statement(subject.subject_uri, 
                   RDF::Vocab::LDP.isMemberOfRelation, 
                   RDF::Vocab::DC.isPartOf)
  end

  describe '#add' do
    let(:resource_uri) { RDF::URI('http://ex.org/too-ticky') }

    it 'raises an error if the membership resource does not exist' do
      expect { subject.add(resource_uri) }
        .to raise_error RDF::LDP::NotAcceptable
      expect(subject.containment_triples).to be_empty
    end

    context 'when the membership resource exists' do
      before { subject.create('', 'application/n-triples') }

      it 'adds membership triple to membership resource' do
        expect(subject.add(resource_uri).graph)
          .to have_statement subject.make_membership_triple(resource_uri)
      end

      it 'updates last_modified for membership resource' do
        expect { subject.add(resource_uri).graph }
          .to change { subject.last_modified }
      end

      it 'updates etag for for membership resource' do
        expect { subject.add(resource_uri).graph }
          .to change { subject.etag }
      end

      it 'adds membership triple to custom membership resource' do
        repo = RDF::Repository.new
        subject = described_class.new(uri, repo)
        mem_rs = RDF::LDP::RDFSource.new(RDF::URI('http://ex.org/mymble'), 
                                         repo)

        g = RDF::Graph.new << RDF::Statement(subject.subject_uri,
                                        RDF::Vocab::LDP.membershipResource,
                                        mem_rs.subject_uri)

        subject.create(g.dump(:ntriples), 'application/n-triples')
        mem_rs.create('', 'application/n-triples')
        
        subject.add(resource_uri)

        expect(mem_rs.graph)
          .to have_statement subject.make_membership_triple(resource_uri)
      end

      it 'adds membership triple to membership resource with #fragment' do
        repo = RDF::Repository.new
        subject = described_class.new(uri, repo)

        mem_rs = subject.subject_uri / '#membership'

        g = RDF::Graph.new << RDF::Statement(subject.subject_uri,
                                        RDF::Vocab::LDP.membershipResource,
                                        mem_rs)

        subject.create(g.dump(:ttl), 'application/n-triples')
        expect(subject.add(resource_uri).graph)
          .to have_statement subject.make_membership_triple(resource_uri)
      end

      it 'adds membership triple to LDP-NR membership resource' do
        repo = RDF::Repository.new
        container = described_class.new(uri, repo)

        nr = RDF::LDP::NonRDFSource.new('http://example.org/moomin_file',
                                        repo)

        g = RDF::Graph.new << RDF::Statement(subject.subject_uri,
                                             RDF::Vocab::LDP.membershipResource,
                                             nr.to_uri)

        container.create(g.dump(:ntriples), 'application/n-triples')
        nr.create(StringIO.new(''), 'application/n-triples')

        container.add(resource_uri)
        expect(nr.description.graph)
          .to have_statement container.make_membership_triple(resource_uri)
      end

      context 'with multiple membership resources' do
        it 'raises an error' do
          subject.graph << RDF::Statement(subject.subject_uri,
                                          RDF::Vocab::LDP.membershipResource,
                                          subject.subject_uri)
          subject.graph << RDF::Statement(subject.subject_uri,
                                          RDF::Vocab::LDP.membershipResource,
                                          (subject.subject_uri / 'moomin'))

          expect { subject.add(resource_uri) }
            .to raise_error RDF::LDP::RequestError
          expect(subject.containment_triples).to be_empty
        end
      end
    end
  end

  describe '#remove' do
    let(:resource_uri) { RDF::URI('http://ex.org/too-ticky') }

    it 'raises an error if the membership resource does not exist' do
      expect { subject.remove(resource_uri) }
        .to raise_error RDF::LDP::NotAcceptable
    end

    context 'when the membership resource exists' do
      before { subject.create('', 'application/n-triples') }

      it 'removes membership triple to membership resource' do
        subject.graph << subject.make_membership_triple(resource_uri)
        expect(subject.remove(resource_uri).graph)
          .not_to have_statement subject.make_membership_triple(resource_uri)
      end
    end

  end

  describe '#membership_constant_uri' do
    it 'when created defaults to #subject_uri' do
      subject.create('', 'application/n-triples')
      expect(subject.membership_constant_uri).to eq subject.subject_uri
      expect(subject.graph)
        .to have_statement RDF::Statement(subject.subject_uri, 
                                          RDF::Vocab::LDP.membershipResource, 
                                          subject.subject_uri)
    end

    it 'gives membership resource' do
      membership_resource = (subject.subject_uri / '#too-ticky')
      subject.graph << RDF::Statement(subject.subject_uri, 
                                      RDF::Vocab::LDP.membershipResource, 
                                      membership_resource)
      expect(subject.membership_constant_uri).to eq membership_resource
    end

    it 'raises an error if multiple are present' do
      membership_resource = (subject.subject_uri / '#too-ticky')
      subject.graph << RDF::Statement(subject.subject_uri, 
                                      RDF::Vocab::LDP.membershipResource, 
                                      membership_resource)

      subject.graph << RDF::Statement(subject.subject_uri, 
                                      RDF::Vocab::LDP.membershipResource, 
                                      subject.subject_uri)

      expect { subject.membership_constant_uri }
        .to raise_error RDF::LDP::RequestError
    end
  end

  describe '#membership_predicate' do
    it 'when created returns a uri' do
      subject.create('', 'application/n-triples')
      expect(subject.membership_predicate).to be_a RDF::URI
    end

    it 'gives assigned member relation predicate for hasMember' do
      subject.graph << has_member_statement

      expect(subject.membership_predicate).to eq RDF::Vocab::DC.hasPart
    end

    it 'gives assigned member relation predicate for isMemberOf' do
      subject.graph << is_member_of_statement

      expect(subject.membership_predicate).to eq RDF::Vocab::DC.isPartOf
    end

    it 'raises an error if multiple relation predicates are present' do
      subject.graph << has_member_statement
      subject.graph << is_member_of_statement

      expect { subject.membership_predicate }
        .to raise_error RDF::LDP::RequestError
    end
  end

  describe '#make_membership_triple' do
    context 'with hasMember' do
      before do
        g = RDF::Graph.new << has_member_statement
        subject.create(g.dump(:ntriples), 'application/n-triples')
      end

      it 'is constant - predicate - derived' do
        expect(subject.make_membership_triple(uri))
          .to eq RDF::Statement(subject.membership_constant_uri, 
                                subject.membership_predicate, 
                                uri)
      end
    end

    context 'with isMemberOf' do
      before do
        g = RDF::Graph.new << is_member_of_statement
        subject.create(g.dump(:ntriples), 'application/n-triples')
      end

      it 'is derived - predicate - constant' do
        expect(subject.make_membership_triple(uri))
          .to eq RDF::Statement(uri,
                                subject.membership_predicate, 
                                subject.membership_constant_uri)
      end
    end
  end
end
