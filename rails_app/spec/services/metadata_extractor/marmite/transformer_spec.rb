# frozen_string_literal: true

RSpec.describe MetadataExtractor::Marmite::Transformer do
  let(:transformer) { described_class.new(xml) }

  describe '#to_descriptive_metadata' do
    context 'when record is a book' do
      let(:expected_metadata) do
        {
          'identifier' => [{ 'value' => '9923478503503681' }, { 'value' =>  'sts- n.r* n.n. di12 (3) 1598 (A)' }, { 'value' => '(OCoLC)ocm16660686' },
                           { 'value' => '(OCoLC)16660686' }, { 'value' => '2347850' }, { 'value' => '(PU)2347850-penndb-Voyager' }],
          'item_type' => [{ 'value' => 'Books' }],
          'language' => [{ 'value' => 'German' }],
          'creator' => [{ 'value' => 'Ercker, Lazarus, -1594.' }],
          'title' => [
            { 'value' => 'Beschreibung aller fürnemisten Mineralischen Ertzt vnnd Berckwercksarten : wie dieselbigen vnd eine jede in Sonderheit jrer Natur vnd Eygenschafft nach, auff alle Metalla probirt, vnd im kleinen Fewr sollen versucht werden, mit Erklärung etlicher fürnemer nützlicher Schmeltzwerck im grossen Feuwer, auch Scheidung Goldts, Silbers, vnd anderer Metalln, sampt einem Bericht des Kupffer Saigerns, Messing brennens, vnd Salpeter Siedens, auch aller saltzigen Minerischen proben, vnd was denen allen anhengig : in fünff Bücher verfast, dessgleichen zuvorn niemals in Druck kommen ... : auffs newe an vielen Orten mit besserer Aussführung, vnd mehreren Figurn erklärt / durch den weitberühmten Lazarum Erckern, der Röm. Kay. May. Obersten Bergkmeister vnd Buchhalter in Königreich Böhem &c. ...' }
          ],
          'publisher' => [{ 'value' => 'Gedruckt zu Franckfurt am Mayn : Durch Johan Feyerabendt, 1598.' }],
          'relation' => [{ 'value' => 'Facsimile https://colenda.library.upenn.edu/catalog/81431-p3df6k90j' }],
          'format' => [{ 'value' => '4 unnumbered leaves, 134 leaves, 4 unnumbered leaves : illustrations ; 31 cm (folio)' }],
          'notes' => [{ 'value' => 'Signatures: )(⁴ A-Z⁴ a-k⁴ l⁶.' }, { 'value' => 'Leaves printed on both sides.' }, { 'value' => 'The last leaf is blank.' },
                      { 'value' => 'Woodcut illustrations, initials and tail-pieces.' }, { 'value' => 'Title page printed in black and red.' }, { 'value' => 'Online version available via Colenda' }, { 'value' => '"Erratum" on verso of last printed leaf.' }, { 'value' => 'Printed marginalia.' }],
          'provenance' => [{ 'value' => 'Smith, Edgar Fahs, 1854-1928 (autograph, 1917)' }, { 'value' => 'Wright, H. (autograph, 1870)' }],
          'description' => [{ 'value' => "Penn Libraries copy has Edgar Fahs Smith's autograph on front free endpaper; autograph of H. Wright on front free endpaper; effaced ms. inscription (autograph?) on title leaf." }],
          'subject' => [{ 'value' => 'Metallurgy -- Early works to 1800.'}, { 'value' => 'Assaying.' }, { 'value' => 'Assaying -- Early works to 1800.' },
                        { 'value' => 'Metallurgy.' }],
          'date' => [{ 'value' => '1598' }],
          'personal_name' => [{ 'value' => 'Feyerabend, Johann, 1550-1599, printer.' }],
          'geographic_subject' => [{ 'value' => 'Germany -- Frankfurt am Main.' }],
          'collection' => [{ 'value' => 'Edgar Fahs Smith Memorial Collection (University of Pennsylvania)' }],
          'call_number' => [{ 'value' => 'Folio TN664 .E7 1598' }],
          'corporate_name' => [{ 'value' => 'Edgar Fahs Smith Memorial Collection (University of Pennsylvania)' }],
          'coverage' => [{ 'value' => '1598' }]
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
          'abstract' => [{ 'value' => "Beginning of Sigebert of Gembloux's continuation of the chronicle of Jerome, in which he traces the reigns of kings of various kingdoms.  The last reference is to Pope Zosimus (417 CE; f. 6v)." }],
          'notes' => [{ 'value' => 'Title supplied by cataloger.' },
                      { 'value' => 'Origin:  Probably written in Belgium, possibly in Gembloux (inscription on title page of printed work, Bibliotheca Gemblacensis), in the late 15th century (Zacour-Hirsch).' }, { 'value' => 'Ms. gathering.' }, { 'value' => 'Collation:  Paper, 10; 1² 2⁸ (f. 7-10 blank).' }, { 'value' => "Binding:  Bound with Strabo's Geographia (Paris:  Gourmont, 1512) in 18th-century calf including gilt spine title Initium Chronic[i] Sicebert[i] MS." }, { 'value' => 'Script:  Written in Gothic cursive script.' }, { 'value' => 'Decoration: 4-line initial (f. 2r) and 3-line initial (f. 1r) in red; paragraph marks in red followed by initials slashed with red on first page (f. 1r).' }, { 'value' => 'Layout:  Written in 47-50 long lines; frame-ruled in lead.' }, { 'value' => 'Latin.'}],
          'call_number' => [{ 'value' => 'Folio GrC St812 Ef512g' }],
          'citation_note' => [{ 'value' => 'Described in Zacour, Norman P. and Hirsch, Rudolf. Catalogue of Manuscripts in the Libraries of the University of Pennsylvania to 1800 (Philadelphia: University of Pennsylvania Press, 1965), Supplement A (1) Library Chronicle 35 (1969),' }],
          'creator' => [{ 'value' => 'Sigebert, of Gembloux, approximately 1030-1112.' }],
          'format' => [{ 'value' => '10 leaves : paper ; 263 x 190 mm bound to 218 x 155 mm' }],
          'identifier' => [{ 'value' => '9961263533503681' }, { 'value' => '(OCoLC)ocn873818335' }, { 'value' => '(OCoLC)873818335' }, { 'value' => '(PU)6126353-penndb-Voyager' }],
          'item_type' => [{ 'value' => 'Manuscripts' }],
          'language' => [{ 'value' => 'Latin' }],
          'personal_name' => [{ 'value' => 'Sigebert, of Gembloux, approximately 1030-1112. Chronicon.' }],
          'provenance' => [{ 'value' => 'Sold by Bernard M. Rosenthal (New York), 1964.' }],
          'publisher' => [{ 'value' => '[Belgium], [between 1475 and 1499?]' }],
          'relation' => [{ 'value' => 'Digital facsimile for browsing (Colenda) https://colenda.library.upenn.edu/catalog/81431-p3833nf29' }],
          'subject' => [{ 'value' => 'World history.' }, { 'value' => 'World history -- Early works to 1800.' }, { 'value' => 'Chronicles.' },
                        { 'value' => 'Manuscripts, Renaissance.' }, { 'value' => 'Manuscripts, Latin.' }],
          'title' => [{ 'value' => '[Partial copy of Chronicon].' }, { 'value' => 'Initium Chronici Siceberti.' }],
          'date' => [{ 'value' => '1475' }]
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

    context 'when xml contains languages in 008 and 041' do
      let(:xml) do
        <<~XML
          <?xml version="1.0"?>
          <marc:records xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
            <marc:record>
              <marc:controlfield tag="001">99760863503681</marc:controlfield>
              <marc:controlfield tag="008">870304s1931    nyu           000 1 eng  </marc:controlfield>
              <marc:datafield ind1="1" ind2=" " tag="041">
                <marc:subfield code="a">eng</marc:subfield>
                <marc:subfield code="h">rus</marc:subfield>
              </marc:datafield>
            </marc:record>
          </marc:records>
        XML
      end

      it 'extracts expected languages' do
        expect(transformer.to_descriptive_metadata['language'].pluck('value')).to contain_exactly('English', 'Russian')
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
