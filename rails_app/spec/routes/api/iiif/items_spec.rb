# frozen_string_literal: true

# NOTE: if using subdomain constraint, get: should include full hostname,
#       and the route_to hash should include a subdomain: key
describe 'API::IIIF::ItemsController', type: :routing do
  let(:controller) { 'api/iiif/items' }

  it 'routes /iiif/items/:uuid/manifest to v3 manifest' do
    expect(get: '/iiif/items/123-abc/manifest').to route_to(
      controller: controller,
      action: 'manifest',
      uuid: '123-abc',
      version: '3'
    )
  end

  it 'routes /iiif/2/items/:uuid/manifest to v2 manifest' do
    expect(get: '/iiif/2/items/123-abc/manifest').to route_to(
      controller: controller,
      action: 'manifest',
      uuid: '123-abc',
      version: '2'
    )
  end
end
