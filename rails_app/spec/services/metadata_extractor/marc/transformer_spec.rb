# frozen_string_literal: true

RSpec.describe MetadataExtractor::MARC::Transformer do
  let(:transformer) { described_class.new(rules: MetadataExtractor::MARC::PennRules) }
  let(:xml) { '' }

  describe '#run' do
    context 'when record is a book' do
      # rubocop:disable Layout/LineLength
      let(:expected_metadata) do
        {
          coverage: [{ value: 'Early works to 1800' }],
          language: [{ value: 'German', uri: 'http://id.loc.gov/vocabulary/iso639-2/ger' }],
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
      let(:xml) { File.read(file_fixture('alma/marc_xml/book-1.xml')) }

      it 'generates_expected_xml' do
        expect(transformer.run(xml)).to eq expected_metadata
      end
    end

    context 'when record is a manuscript' do
      # rubocop:disable Layout/LineLength
      let(:expected_metadata) do
        {
          date: [{ value: '1475' }],
          description: [{ value: "Beginning of Sigebert of Gembloux's continuation of the chronicle of Jerome, in which he traces the reigns of kings of various kingdoms.  The last reference is to Pope Zosimus (417 CE; f. 6v)." }],
          item_type: [{ value: 'Text', uri: 'http://purl.org/dc/dcmitype/Text' }],
          language: [{ value: 'Latin', uri: 'http://id.loc.gov/vocabulary/iso639-2/lat' }],
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
            { value: 'Latin.' },
            { value: 'Related Work: Sigebert, of Gembloux, approximately 1030-1112. Chronicon.' }
          ],
          physical_location: [
            { value: 'Kislak Center for Special Collections, Rare Books and Manuscripts, Manuscripts, Folio GrC St812 Ef512g' }
          ],
          physical_format: [
            { value: 'manuscripts (documents)', uri: 'http://vocab.getty.edu/aat/300028569' },
            { value: 'chronicles', uri: 'http://vocab.getty.edu/aat/300026361' },
            { value: 'Manuscripts, Latin' },
            { value: 'Manuscripts, Renaissance' }
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
      let(:xml) { File.read(file_fixture('alma/marc_xml/manuscript-1.xml')) }

      it 'generates expected xml' do
        expect(transformer.run(xml)).to eq expected_metadata
      end
    end
  end
end
