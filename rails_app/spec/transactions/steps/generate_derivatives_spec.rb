# frozen_string_literal: true

describe Steps::GenerateDerivatives do
  let(:generate_derivatives_step) { described_class.new(derivative_generator_class, derivative_type) }
  let(:derivative_generator_class) { DerivativeService::Item::Derivatives }
  let(:derivative_type) { 'iiif_manifest' }

  before { freeze_time }
  after  { unfreeze_time }

  describe '#call' do
    subject(:result) do
      change_set = ItemChangeSet.new(persist(:item_resource))
      generate_derivatives_step.call(change_set)
    end

    before do
      derivative_generator = instance_double(derivative_generator_class)
      allow(derivative_generator_class).to receive(:new).and_return(derivative_generator)
      allow(derivative_generator).to receive(derivative_type).and_return(derivative_file)
    end

    context 'when derivatives are generated' do
      let(:derivative_file) { DerivativeService::DerivativeFile.new(mime_type: 'application/json') }

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'adds derivative resource' do
        expect(result.value!.derivatives.count).to be 1
        expect(result.value!.derivatives.first).to have_attributes(
          file_id: an_instance_of(Valkyrie::ID),
          type: derivative_type.to_s,
          mime_type: 'application/json',
          size: 0,
          generated_at: DateTime.current
        )
      end

      it 'creates iiif manifest and stores it' do
        expect(result.value!.derivatives.count).to be 1
        expect(
          Valkyrie::StorageAdapter.find_by(id: result.value!.derivatives.first.file_id)
        ).to be_a Valkyrie::StorageAdapter::File
      end
    end

    context 'when derivatives are not generated' do
      let(:derivative_file) { nil }

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'does not add a derivative resource' do
        expect(result.value!.derivatives.count).to be 0
      end
    end

    context 'when keeping other derivatives that are already present' do
      subject(:result) do
        pdf_derivative = DerivativeResource.new(file_id: Valkyrie::ID.new(SecureRandom.uuid), type: 'pdf',
                                                mime_type: 'application/pdf', size: 0, generated_at: DateTime.current)
        change_set = ItemChangeSet.new(persist(:item_resource, derivatives: [pdf_derivative]))
        generate_derivatives_step.call(change_set)
      end

      let(:generate_derivatives_step) do
        described_class.new(derivative_generator_class, derivative_type, replace_all: false)
      end
      let(:derivative_file) { DerivativeService::DerivativeFile.new(mime_type: 'application/json') }

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'adds derivative resource' do
        expect(result.value!.derivatives.count).to be 2
        expect(result.value!.derivatives.map(&:type)).to contain_exactly('iiif_manifest', 'pdf')
      end

      it 'creates iiif manifest and stores it' do
        iiif_manifest = result.value!.derivatives.find { |d| d.type == derivative_type }
        expect(iiif_manifest).to have_attributes(file_id: an_instance_of(Valkyrie::ID),
                                                 type: derivative_type.to_s,
                                                 mime_type: 'application/json',
                                                 size: 0,
                                                 generated_at: DateTime.current)
        expect(Valkyrie::StorageAdapter.find_by(id: iiif_manifest.file_id)).to be_a Valkyrie::StorageAdapter::File
      end
    end

    context 'when an error is raised while generating derivatives' do
      let(:derivative_file) { DerivativeService::DerivativeFile.new(mime_type: 'application/json') }

      before do
        allow(derivative_file).to receive(:cleanup!)
        allow(Valkyrie::StorageAdapter).to receive(:find).and_raise(StandardError)
      end

      it 'cleans up the temporary derivative file' do
        result
        expect(derivative_file).to have_received(:cleanup!)
      end

      it 'returns a failure' do
        expect(result.failure?).to be true
      end
    end
  end

  describe '#find_storage' do
    let(:storage) { generate_derivatives_step.send(:find_storage, derivative_file) }

    context 'when derivative file is an iiif_image' do
      let(:derivative_file) { DerivativeService::DerivativeFile.new(mime_type: 'image/tiff', iiif_image: true) }

      it 'returns iiif_derivative storage' do
        expect(storage.identifier_prefix).to eql 'iiif_derivatives'
      end
    end

    context 'when derivative file is an iiif_manifest' do
      let(:derivative_file) { DerivativeService::DerivativeFile.new(mime_type: 'image/tiff', iiif_manifest: true) }

      it 'returns iiif_manifest storage' do
        expect(storage.identifier_prefix).to eql 'iiif_manifests'
      end
    end

    context 'when derivative file is a regular derivative' do
      let(:derivative_file) { DerivativeService::DerivativeFile.new(mime_type: 'image/tiff') }

      it 'returns derivative storage' do
        expect(storage.identifier_prefix).to eql 'derivatives'
      end
    end
  end
end
