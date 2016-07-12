require 'bundler/setup'
require 'benchmark'
require 'ladder'

task :benchmark do
  include Benchmark

  # RDF::Repository:
  # rake benchmark  5.12s user 0.25s system 98% cpu 5.454 total

  # RDF::Mongo::Repository:
  # rake benchmark  11.88s user 1.00s system 73% cpu 17.441 total

  # RDF::Mongo::Repository + Graphable:
  # rake benchmark  12.89s user 1.04s system 74% cpu 18.679 total

  # RDF::Mongo::Repository + Elasticseach Sync:
  # rake benchmark  22.41s user 1.24s system 74% cpu 31.596 total

  # clear repository
  REPOSITORY = Ladder::LDP.settings.repository
  REPOSITORY.clear!

  TURTLE = File.open('etc/doap.ttl')

  SETS = 5
  REPS = 5

  def benchmark(container_class)
    count = RDF::Reader.for(:ttl).new(TURTLE).statements.count
    puts "#{REPOSITORY.class}"
    puts "\n#{container_class.to_uri}"
    puts "\t10 Containers; 100 LDP-RS & LDP-NR per Container;\n\t#{count} statements per LDP-RS; GET/HEAD x 5\n\n"

    Benchmark.benchmark(CAPTION, 7, FORMAT, ">total:", ">avg:") do |bm|
      SETS.times do |i|
        bm.report('LDP-RS POST:') do
          container = container_class.new(RDF::URI("http://example.org/#{container_class}/rs/#{i}"), REPOSITORY)
          container.request(:put, 200, {}, {'CONTENT_TYPE' => 'application/n-triples', 'rack.input' => StringIO.new})

          REPS.times do
            container.request(:post, 200, {}, {'CONTENT_TYPE' => 'text/turtle', 'rack.input' => TURTLE})
          end
        end
      end
    end

    Benchmark.benchmark(CAPTION, 7, FORMAT, ">total:", ">avg:") do |bm|
      SETS.times do |i|
        bm.report('LDP-RS GET:') do
          container = container_class.new(RDF::URI("http://example.org/#{container_class}/rs/#{i}"), REPOSITORY)
          5.times do
            container.graph.objects.each do |rs_uri|
              RDF::LDP::RDFSource.new(rs_uri, REPOSITORY).request(:get, 200, {}, {})
            end
          end
        end
      end
    end

    Benchmark.benchmark(CAPTION, 7, FORMAT, ">total:", ">avg:") do |bm|
      SETS.times do |i|
        bm.report('LDP-RS HEAD:') do
          container = container_class.new(RDF::URI("http://example.org/#{container_class}/rs/#{i}"), REPOSITORY)
          5.times do
            container.graph.objects.each do |rs_uri|
              RDF::LDP::RDFSource.new(rs_uri, REPOSITORY).request(:head, 200, {}, {})
            end
          end
        end
      end
    end

    Benchmark.benchmark(CAPTION, 7, FORMAT, ">total:", ">avg:") do |bm|
      SETS.times do |i|
        bm.report('LDP-RS PUT:') do
          container = container_class.new(RDF::URI("http://example.org/#{container_class}/rs/#{i}"), REPOSITORY)

          container.graph.objects.each do |rs_uri|
            RDF::LDP::RDFSource.new(rs_uri, REPOSITORY).request(:put, 200, {}, {'CONTENT_TYPE' => 'text/turtle', 'rack.input' => StringIO.new})
          end
        end
      end
    end

    Benchmark.benchmark(CAPTION, 7, FORMAT, ">total:", ">avg:") do |bm|
      SETS.times do |i|
        bm.report('LDP-NR:') do
          container = container_class.new(RDF::URI("http://example.org/#{container_class}/nr/#{i}"), REPOSITORY)
          container.request(:put, 200, {}, {'CONTENT_TYPE' => 'application/n-triples', 'rack.input' => StringIO.new})

          REPS.times do
            container.request(:post, 200, {}, {'HTTP_LINK' => '<http://www.w3.org/ns/ldp#NonRDFSource>;rel=type', 'CONTENT_TYPE' => 'image/tiff', 'rack.input' => StringIO.new('testing')})
          end
        end
      end
    end
    REPOSITORY.clear!
  end

  benchmark(RDF::LDP::Container)
  benchmark(RDF::LDP::DirectContainer)
  benchmark(RDF::LDP::IndirectContainer)

  REPOSITORY.clear!
end

task :bm => :benchmark