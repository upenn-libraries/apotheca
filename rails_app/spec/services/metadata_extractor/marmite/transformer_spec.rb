# frozen_string_literal: true

RSpec.describe MetadataExtractor::Marmite::Transformer do
  let(:transformer) { described_class.new(xml) }

  describe '#to_descriptive_metadata' do
    context 'when record is a book' do
      let(:expected_metadata) do
        {
          coverage: [{ value: 'Early works to 1800.' }],
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
          extent: [{ value: '4 unnumbered leaves, 134 leaves, 4 unnumbered leaves :illustrations ;31 cm (folio)' }],
          item_type: [{ value: 'Text', uri: 'http://purl.org/dc/dcmitype/Text' }],
          location: [{ value: 'Germany -- Frankfurt am Main.' }],
          publisher: [{ value: 'Durch Johan Feyerabendt,' }],
          relation: [{ value: 'Facsimile: https://colenda.library.upenn.edu/catalog/81431-p3df6k90j' }],
          provenance: [{ value: 'Smith, Edgar Fahs, 1854-1928 (autograph, 1917)' }, { value: 'Wright, H. (autograph, 1870)' }],
          subject: [
            { value: 'Metallurgy -- Early works to 1800.', uri: 'http://id.loc.gov/authorities/subjects/sh2008107709' },
            { value: 'Metallurgy.', uri: 'http://id.worldcat.org/fast/1018005' },
            { value: 'Assaying -- Early works to 1800.' },
            { value: 'Assaying.', uri: 'http://id.worldcat.org/fast/818995' }
          ],
          date: [{ value: '1598' }],
          name: [
            { value: 'Ercker, Lazarus, -1594.', uri: 'http://id.loc.gov/authorities/names/n85215805' },
            { value: 'Feyerabend, Johann, 1550-1599,', uri: 'http://id.loc.gov/authorities/names/nr95034041', role: [{ value: 'printer.' }] },
          ],
          collection: [{ value: 'Edgar Fahs Smith Memorial Collection (University of Pennsylvania)' }],
          physical_location: [{ value: 'KislakCntr scsmith Folio TN664 .E7 1598' }],
          title: [
            { value: 'Beschreibung aller fürnemisten Mineralischen Ertzt vnnd Berckwercksarten : wie dieselbigen vnd eine jede in Sonderheit jrer Natur vnd Eygenschafft nach, auff alle Metalla probirt, vnd im kleinen Fewr sollen versucht werden, mit Erklärung etlicher fürnemer nützlicher Schmeltzwerck im grossen Feuwer, auch Scheidung Goldts, Silbers, vnd anderer Metalln, sampt einem Bericht des Kupffer Saigerns, Messing brennens, vnd Salpeter Siedens, auch aller saltzigen Minerischen proben, vnd was denen allen anhengig : in fünff Bücher verfast, dessgleichen zuvorn niemals in Druck kommen ... : auffs newe an vielen Orten mit besserer Aussführung, vnd mehreren Figurn erklärt /' }
          ]
        }
      end
      let(:xml) { File.read(file_fixture('marmite/marc_xml/book-1.xml')) }

      it 'generates_expected_xml' do
        expect(transformer.to_descriptive_metadata).to eq expected_metadata
      end
    end

    context 'when record is a manuscript' do
      let(:expected_metadata) do
        {
          date: [{ value: '1475' }],
          description: [{ value: "Beginning of Sigebert of Gembloux's continuation of the chronicle of Jerome, in which he traces the reigns of kings of various kingdoms.  The last reference is to Pope Zosimus (417 CE; f. 6v)." }],
          item_type: [{ value: 'Text', uri: 'http://purl.org/dc/dcmitype/Text' }],
          language: [{ value: 'Latin', uri: 'https://id.loc.gov/vocabulary/iso639-2/lat' }],
          extent: [{ value: '10 leaves :paper ;263 x 190 mm bound to 218 x 155 mm' }],
          name: [
            { value: 'Sigebert, of Gembloux, approximately 1030-1112.', uri: 'http://id.loc.gov/authorities/names/n87881954' },
            { value: 'Sigebert, of Gembloux, approximately 1030-1112.' }
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
          physical_location: [{ value: 'KislakCntr scmss Folio GrC St812 Ef512g' }],
          physical_format: [
            { value: 'Chronicles.', uri: 'http://vocab.getty.edu/aat/300026361' },
            { value: 'Manuscripts, Latin.' },
            { value: 'Manuscripts, Renaissance.' }
          ],
          provenance: [{ value: 'Sold by Bernard M. Rosenthal (New York), 1964.' }],
          relation: [{ value: 'Digital facsimile for browsing (Colenda): https://colenda.library.upenn.edu/catalog/81431-p3833nf29' }],
          coverage: [{ value: 'Early works to 1800.' }],
          subject: [
            { value: 'World history -- Early works to 1800.', uri: 'http://id.loc.gov/authorities/subjects/sh85148202' },
            { value: 'World history.', uri: 'http://id.worldcat.org/fast/1181345' }
          ],
          alt_title: [{ value: 'Initium Chronici Siceberti.' }],
          title: [{ value: '[Partial copy of Chronicon].' }]
        }
      end
      let(:xml) { File.read(file_fixture('marmite/marc_xml/manuscript-1.xml')) }

      it 'generates expected xml' do
        expect(transformer.to_descriptive_metadata).to eq expected_metadata
      end
    end

    context 'when record is a non-book' do
      let(:xml) { File.read(file_fixture('marmite/marc_xml/non-book-1.xml')) }

      it 'generates expected xml' do
        expect(transformer.to_descriptive_metadata['item_type']).to be_nil
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
                <marc:subfield code="6">245-01</marc:subfield>
                <marc:subfield code="a">慶安太平記</marc:subfield>
               </marc:datafield>
            </marc:record>
          </marc:records>
        XML
      end

      it 'extracts title and transliterated title' do
        expect(
          transformer.to_descriptive_metadata[:title].pluck(:value)
        ).to contain_exactly('Keian Taiheiki.', '慶安太平記')
      end
    end
  end

  describe '.book?' do
    let(:nokogiri_xml) do
      document = Nokogiri::XML(xml)
      document.remove_namespaces!
      document
    end

    context 'when 7th value in leader field is an `a`' do
      let(:xml) do
        <<~XML
          <?xml version="1.0"?>
          <marc:records xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
            <marc:record>
              <marc:leader>03167cam a2200517Ia 4500</marc:leader>
            </marc:record>
          </marc:records>
        XML
      end

      it 'returns true' do
        expect(transformer.send(:book?)).to be true
      end
    end
  end

  describe '.manuscript?' do
    let(:nokogiri_xml) do
      document = Nokogiri::XML(xml)
      document.remove_namespaces!
      document
    end

    context 'when PAULM is present in 040 field' do
      let(:xml) do
        <<~XML
          <?xml version="1.0"?>
          <marc:records xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
            <marc:record>
              <marc:datafield ind1=" " ind2=" " tag="040">
                <marc:subfield code="a">PAULM</marc:subfield>
              </marc:datafield>
            </marc:record>
          </marc:records>
        XML
      end

      it 'returns true' do
        expect(transformer.send(:manuscript?)).to be true
      end
    end

    context 'when appm2 is present in field 040 subfield e' do
      let(:xml) do
        <<~XML
          <?xml version="1.0"?>
          <marc:records xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
            <marc:record>
              <marc:datafield ind1=" " ind2=" " tag="040">
                <marc:subfield code="e">appm2</marc:subfield>
              </marc:datafield>
            </marc:record>
          </marc:records>
        XML
      end

      it 'returns true' do
        expect(transformer.send(:manuscript?)).to be true
      end
    end

    context 'when field 040 is empty' do
      let(:xml) do
        <<~XML
          <?xml version="1.0"?>
          <marc:records xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
            <marc:record/>
          </marc:records>
        XML
      end

      it 'returns false' do
        expect(transformer.send(:manuscript?)).to be false
      end
    end
  end
end
