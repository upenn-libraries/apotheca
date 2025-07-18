
# Adds `access` derivative to asset. Requires `asset` variable to be set.
shared_context 'with access derivative' do
  let(:access_derivative) do
    uploaded_file = ActionDispatch::Http::UploadedFile.new(
      tempfile: File.new(Rails.root.join('spec/fixtures/files/trade_card/original/front.tif')),
      filename: 'access', type: 'image/tiff'
    )
    iiif_derivative_storage = Valkyrie::StorageAdapter.find(:iiif_derivatives)
    file = iiif_derivative_storage.upload(file: uploaded_file, resource: asset, original_filename: 'access')

    DerivativeResource.new(file_id: file.id, mime_type: 'image/tiff',
                           size: file.size, type: 'access', generated_at: DateTime.current)
  end

  before do
    change_set = AssetChangeSet.new(asset)
    change_set.derivatives = [access_derivative] + asset.derivatives.reject(&:iiif_image?)
    resource = change_set.sync
    persister = Valkyrie::MetadataAdapter.find(:postgres_solr_persister).persister
    persister.save(resource: resource)
  end
end