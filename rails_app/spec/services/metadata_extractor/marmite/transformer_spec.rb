# frozen_string_literal: true

RSpec.describe MetadataExtractor::Marmite::Transformer do
  let(:transformer) { described_class.new(xml) }
  let(:xml) { '' }

  describe '#to_descriptive_metadata' do
    context 'when record is a book' do
      # rubocop:disable Layout/LineLength
      let(:expected_metadata) do
        {
          coverage: [{ value: 'Early works to 1800' }],
          language: [{ value: 'German', uri: 'https://id.loc.gov/vocabulary/iso639-2/ger' }],
          note: [
            { value: 'Leaves printed on both sides.' },
            { value: 'Signatures: )(⁴ A-Z⁴ a-k⁴ l⁶.' },
            { value: 'The last leaf is blank.' },
            { value: 'Woodcut illustrations, initials and tail-pieces.' },
            { value: 'Title page printed in black and red.' },
            { value: 'Printed marginalia.' },
            { value: '"Erratum" on verso of last printed leaf.' },
            { value: 'Online version available via Colenda' },
            { value: 'Penn Libraries copy has Edgar Fahs Smith\'s autograph on front free endpaper; autograph of H. Wright on front free endpaper; effaced ms. inscription (autograph?) on title leaf.' }
          ],
          extent: [{ value: '4 unnumbered leaves, 134 leaves, 4 unnumbered leaves : illustrations ; 31 cm (folio)' }],
          item_type: [{ value: 'Text', uri: 'http://purl.org/dc/dcmitype/Text' }],
          location: [{ value: 'Germany -- Frankfurt am Main.' }],
          publisher: [{ value: 'Durch Johan Feyerabendt' }],
          relation: [{ value: 'Facsimile: https://colenda.library.upenn.edu/catalog/81431-p3df6k90j' }],
          provenance: [
            { value: 'Beck, Helmut, 1919-2001, former owner.' },
            { value: 'Smith, Edgar Fahs, 1854-1928 (autograph, 1917)' },
            { value: 'Wright, H. (autograph, 1870)' }
          ],
          subject: [
            { value: 'Metallurgy -- Early works to 1800', uri: 'http://id.loc.gov/authorities/subjects/sh2008107709' },
            { value: 'Metallurgy', uri: 'http://id.worldcat.org/fast/1018005' },
            { value: 'Assaying -- Early works to 1800' },
            { value: 'Assaying', uri: 'http://id.worldcat.org/fast/818995' }
          ],
          date: [{ value: '1598' }],
          name: [
            { value: 'Ercker, Lazarus, -1594', uri: 'http://id.loc.gov/authorities/names/n85215805' },
            { value: 'Feyerabend, Johann, 1550-1599', uri: 'http://id.loc.gov/authorities/names/nr95034041',
              role: [{ value: 'printer' }] }
          ],
          collection: [{ value: 'Edgar Fahs Smith Memorial Collection (University of Pennsylvania)' }],
          physical_format: [{ uri: 'http://vocab.getty.edu/aat/300028051', value: 'books' }],
          physical_location: [{ value: 'Kislak Center for Special Collections, Rare Books and Manuscripts, E.F. Smith Collection, Folio TN664 .E7 1598' }],
          title: [
            { value: 'Beschreibung aller fürnemisten Mineralischen Ertzt vnnd Berckwercksarten : wie dieselbigen vnd eine jede in Sonderheit jrer Natur vnd Eygenschafft nach, auff alle Metalla probirt, vnd im kleinen Fewr sollen versucht werden, mit Erklärung etlicher fürnemer nützlicher Schmeltzwerck im grossen Feuwer, auch Scheidung Goldts, Silbers, vnd anderer Metalln, sampt einem Bericht des Kupffer Saigerns, Messing brennens, vnd Salpeter Siedens, auch aller saltzigen Minerischen proben, vnd was denen allen anhengig : in fünff Bücher verfast, dessgleichen zuvorn niemals in Druck kommen ... : auffs newe an vielen Orten mit besserer Aussführung, vnd mehreren Figurn erklärt' }
          ]
        }
      end
      # rubocop:enable Layout/LineLength
      let(:xml) { File.read(file_fixture('marmite/marc_xml/book-1.xml')) }

      it 'generates_expected_xml' do
        expect(transformer.to_descriptive_metadata).to eq expected_metadata
      end
    end

    context 'when record is a manuscript' do
      # rubocop:disable Layout/LineLength
      let(:expected_metadata) do
        {
          date: [{ value: '1475' }],
          description: [{ value: "Beginning of Sigebert of Gembloux's continuation of the chronicle of Jerome, in which he traces the reigns of kings of various kingdoms.  The last reference is to Pope Zosimus (417 CE; f. 6v)." }],
          item_type: [{ value: 'Text', uri: 'http://purl.org/dc/dcmitype/Text' }],
          language: [{ value: 'Latin', uri: 'https://id.loc.gov/vocabulary/iso639-2/lat' }],
          extent: [{ value: '10 leaves : paper ; 263 x 190 mm bound to 218 x 155 mm' }],
          name: [
            { value: 'Sigebert, of Gembloux, approximately 1030-1112',
              uri: 'http://id.loc.gov/authorities/names/n87881954' }
          ],
          note: [
            { value: 'Ms. gathering.' },
            { value: 'Title supplied by cataloger.' },
            { value: 'Collation:  Paper, 10; 1² 2⁸ (f. 7-10 blank).' },
            { value: 'Layout:  Written in 47-50 long lines; frame-ruled in lead.' },
            { value: 'Script:  Written in Gothic cursive script.' },
            { value: 'Decoration: 4-line initial (f. 2r) and 3-line initial (f. 1r) in red; paragraph marks in red followed by initials slashed with red on first page (f. 1r).' },
            { value: "Binding:  Bound with Strabo's Geographia (Paris:  Gourmont, 1512) in 18th-century calf including gilt spine title Initium Chronic[i] Sicebert[i] MS." },
            { value: 'Origin:  Probably written in Belgium, possibly in Gembloux (inscription on title page of printed work, Bibliotheca Gemblacensis), in the late 15th century (Zacour-Hirsch).' },
            { value: 'Latin.' }
          ],
          physical_location: [
            { value: 'Kislak Center for Special Collections, Rare Books and Manuscripts, Manuscripts, Folio GrC St812 Ef512g' }
          ],
          physical_format: [
            { value: 'Chronicles', uri: 'http://vocab.getty.edu/aat/300026361' },
            { value: 'Manuscripts, Latin' },
            { value: 'Manuscripts, Renaissance' },
            { value: 'manuscripts (documents)', uri: 'http://vocab.getty.edu/aat/300028569' }
          ],
          provenance: [{ value: 'Sold by Bernard M. Rosenthal (New York), 1964.' }],
          relation: [
            { value: 'Digital facsimile for browsing (Colenda): https://colenda.library.upenn.edu/catalog/81431-p3833nf29' }
          ],
          coverage: [{ value: 'Early works to 1800' }],
          subject: [
            { value: 'World history -- Early works to 1800', uri: 'http://id.loc.gov/authorities/subjects/sh85148202' },
            { value: 'World history', uri: 'http://id.worldcat.org/fast/1181345' }
          ],
          alt_title: [{ value: 'Initium Chronici Siceberti.' }],
          title: [{ value: '[Partial copy of Chronicon]' }]
        }
      end
      # rubocop:enable Layout/LineLength
      let(:xml) { File.read(file_fixture('marmite/marc_xml/manuscript-1.xml')) }

      it 'generates expected xml' do
        expect(transformer.to_descriptive_metadata).to eq expected_metadata
      end
    end

    context 'when record is a periodical' do
      let(:xml) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <marc:records xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
            <marc:record>
              <marc:leader>07339cas a2201009 a 4500</marc:leader>
              <marc:controlfield tag="001">9931746853503681</marc:controlfield>
              <marc:controlfield tag="005">20230914075419.0</marc:controlfield>
              <marc:controlfield tag="008">830729d18601926enkmr p       0   a0eng c</marc:controlfield>
            </marc:record>
          </marc:records>
        XML
      end

      let(:physical_format) do
        [{ uri: 'http://vocab.getty.edu/aat/300026642', value: 'serials (publications)' },
         { uri: 'http://vocab.getty.edu/aat/300026657', value: 'periodicals' }]
      end

      it 'extracts expected physical_format' do
        expect(transformer.to_descriptive_metadata[:physical_format]).to match_array(physical_format)
      end
    end

    context 'when MARC XML contains languages in 008 and 041' do
      let(:xml) do
        <<~XML
          <?xml version="1.0"?>
          <marc:records xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
            <marc:record>
              <marc:controlfield tag="001">99760863503681</marc:controlfield>
              <marc:controlfield tag="008">870304s1931    nyu           000 1 eng  </marc:controlfield>
              <marc:datafield ind1="1" ind2=" " tag="041">
                <marc:subfield code="a">eng</marc:subfield>
                <marc:subfield code="b">rus</marc:subfield>
              </marc:datafield>
            </marc:record>
          </marc:records>
        XML
      end
      let(:languages) do
        [{ value: 'English', uri: 'https://id.loc.gov/vocabulary/iso639-2/eng' },
         { value: 'Russian', uri: 'https://id.loc.gov/vocabulary/iso639-2/rus' }]
      end

      it 'extracts expected languages' do
        expect(transformer.to_descriptive_metadata[:language]).to match_array(languages)
      end
    end

    context 'when MARC XML contains a transliterated title' do
      let(:xml) do
        <<~XML
          <?xml version="1.0"?>
          <marc:records xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
            <marc:record>
              <marc:controlfield tag="001">9977972653603681</marc:controlfield>
              <marc:datafield ind1="0" ind2="0" tag="245">
                <marc:subfield code="6">880-01</marc:subfield>
                <marc:subfield code="a">Keian Taiheiki.</marc:subfield>
              </marc:datafield>
              <marc:datafield ind1="0" ind2="0" tag="880">
                <marc:subfield code="6">245-01//r</marc:subfield>
                <marc:subfield code="a">慶安太平記</marc:subfield>
               </marc:datafield>
            </marc:record>
          </marc:records>
        XML
      end

      it 'extracts title and transliterated title' do
        expect(
          transformer.to_descriptive_metadata[:title].pluck(:value)
        ).to contain_exactly('Keian Taiheiki', '慶安太平記')
      end
    end

    context 'when MARC XML contains approximate date value' do
      let(:xml) do
        <<~XML
          <?xml version="1.0"?>
          <marc:records xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
            <marc:record>
              <marc:controlfield tag="001">9940417313503681</marc:controlfield>
              <marc:controlfield tag="008">030101q10uu11uuxx 000 0 heb d</marc:controlfield>
            </marc:record>
          </marc:records>
        XML
      end

      it 'converts date to EDFT' do
        expect(
          transformer.to_descriptive_metadata[:date].pluck(:value)
        ).to contain_exactly('10XX')
      end
    end

    context 'when MARC XML contains a date range with both dates' do
      let(:xml) do
        <<~XML
          <?xml version="1.0"?>
          <marc:records xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
            <marc:record>
              <marc:controlfield tag="001">9940417313503681</marc:controlfield>
              <marc:controlfield tag="008">030101i10uu11uuxx 000 0 heb d</marc:controlfield>
            </marc:record>
          </marc:records>
        XML
      end

      it 'converts date to EDFT' do
        expect(transformer.to_descriptive_metadata[:date].pluck(:value)).to contain_exactly('10XX/11XX')
      end
    end

    context 'when MARC XML contains a date range with only end date' do
      let(:xml) do
        <<~XML
          <?xml version="1.0"?>
          <marc:records xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
            <marc:record>
              <marc:controlfield tag="001">9940417313503681</marc:controlfield>
              <marc:controlfield tag="008">030101iuuuu11uuxx 000 0 heb d</marc:controlfield>
            </marc:record>
          </marc:records>
        XML
      end

      it 'converts date to EDFT' do
        expect(transformer.to_descriptive_metadata[:date].pluck(:value)).to contain_exactly('/11XX')
      end
    end

    context 'when MARC XML contains a date range with only start date' do
      let(:xml) do
        <<~XML
          <?xml version="1.0"?>
          <marc:records xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
            <marc:record>
              <marc:controlfield tag="001">9940417313503681</marc:controlfield>
              <marc:controlfield tag="008">030101i10uuuuuuxx 000 0 heb d</marc:controlfield>
            </marc:record>
          </marc:records>
        XML
      end

      it 'converts date to EDFT' do
        expect(transformer.to_descriptive_metadata[:date].pluck(:value)).to contain_exactly('10XX/')
      end
    end

    context 'when MARC XML contains blank value' do
      let(:xml) do
        <<~XML
          <?xml version="1.0"?>
          <marc:records xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
            <marc:record>
              <marc:controlfield tag="001">9958487343503681</marc:controlfield>
              <marc:controlfield tag="008">121105b        pau           000 0 akk d</marc:controlfield>
            </marc:record>
          </marc:records>
        XML
      end

      it 'sets blank date' do
        expect(transformer.to_descriptive_metadata[:date]).to be_nil
      end
    end

    context 'when MARC XML contains a field with a mapped prefix option' do
      let(:xml) do
        <<~XML
          <?xml version="1.0"?>
          <marc:records xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
            <marc:record>
              <marc:datafield ind1="0" ind2="0" tag="505">
                <marc:subfield code="a">formatted contents note</marc:subfield>
                <marc:subfield code="r">statement of responsibility</marc:subfield>
                <marc:subfield code="t">title</marc:subfield>
              </marc:datafield>
              <marc:datafield ind1="0" ind2="0" tag="505">
                <marc:subfield code="a">more contents</marc:subfield>
              </marc:datafield>
            </marc:record>
          </marc:records>
        XML
      end

      it 'prepends the prefix to the expected values' do
        expect(transformer.to_descriptive_metadata).to eq(
          { note: [{ value: 'Table of contents: formatted contents note statement of responsibility title' },
                   { value: 'Table of contents: more contents' }] }
        )
      end
    end

    context 'when MARC XML contains non-aat terms' do
      let(:xml) do
        <<~XML
          <?xml version="1.0"?>
          <marc:records xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
            <marc:record>
              <marc:datafield ind1=" " ind2="7" tag="655">
                <marc:subfield code="a">Notated music.</marc:subfield>
                <marc:subfield code="2">lcgft</marc:subfield>
                <marc:subfield code="0">http://id.loc.gov/authorities/genreForms/gf2014027184</marc:subfield>
              </marc:datafield>
              <marc:datafield ind1=" " ind2="7" tag="655">
                <marc:subfield code="a">Scores.</marc:subfield>
                <marc:subfield code="2">lcgft</marc:subfield>
                <marc:subfield code="0">http://id.loc.gov/authorities/genreForms/gf2014027077</marc:subfield>
              </marc:datafield>
              <marc:datafield ind1=" " ind2="7" tag="655">
                <marc:subfield code="a">Piano music.</marc:subfield>
                <marc:subfield code="2">fast</marc:subfield>
                <marc:subfield code="0">http://id.worldcat.org/fast/1063403</marc:subfield>
              </marc:datafield>
              <marc:datafield ind1=" " ind2="0" tag="655">
                <marc:subfield code="a">Hybrid Music</marc:subfield>
              </marc:datafield>
            </marc:record>
          </marc:records>
        XML
      end

      it 'maps physical format to aat terms' do
        expect(transformer.to_descriptive_metadata[:physical_format]).to contain_exactly(
          MetadataExtractor::Marmite::Transformer::DefaultMappingRules::AAT::SHEET_MUSIC,
          MetadataExtractor::Marmite::Transformer::DefaultMappingRules::AAT::SCORES,
          { value: 'Hybrid Music' }
        )
      end
    end
  end

  describe '#remove_duplicates!' do
    let(:creator) { { value: 'Random, Person', role: [{ value: 'creator' }] } }
    let(:creator_with_uri) { { value: 'Random, Person', uri: 'https://example.com/random-person', role: [{ value: 'creator' }] } }
    let(:illustrator) { { value: 'Random, Person', role: [{ value: 'illustrator' }] } }

    it 'removes duplicate values that have the same role' do
      values = { name: [creator, creator_with_uri] }
      transformer.send(:remove_duplicates!, values, [:name])
      expect(values[:name]).to contain_exactly(creator_with_uri)
    end

    it 'does not remove duplicate values that have different roles' do
      values = { name: [creator, creator_with_uri, illustrator] }
      transformer.send(:remove_duplicates!, values, [:name])
      expect(values[:name]).to contain_exactly(creator_with_uri, illustrator)
    end
  end

  describe '#preferred_values' do
    let(:with_loc_uri) { { value: 'World history', uri: 'http://id.loc.gov/authorities/subjects/sh85148201' } }
    let(:with_fast_uri) { { value: 'World history', uri: 'http://id.worldcat.org/fast/1181345' } }
    let(:with_upenn_uri) { { value: 'World history', uri: 'http://id.library.upenn.edu/world-history' } }
    let(:without_uri) { { value: 'World history' } }

    it 'prefers LOC URIs over other authorities' do
      expect(
        transformer.send(:preferred_values, [with_loc_uri, with_fast_uri, without_uri])
      ).to contain_exactly(with_loc_uri)
    end

    it 'prefers values with URI over values without URIs' do
      expect(
        transformer.send(:preferred_values, [with_fast_uri, with_upenn_uri, without_uri])
      ).to contain_exactly(with_fast_uri, with_upenn_uri)
    end

    it 'removes duplicate' do
      expect(
        transformer.send(:preferred_values, [without_uri, without_uri])
      ).to contain_exactly(without_uri)
    end
  end
end
