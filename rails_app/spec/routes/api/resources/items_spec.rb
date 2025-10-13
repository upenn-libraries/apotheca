# frozen_string_literal: true

# NOTE: if using subdomain constraint, get: should include full hostname,
#       and the route_to hash should include a subdomain: key
describe 'API::Resources::ItemsController', type: :routing do
  let(:controller) { 'api/resources/items' }

  it 'routes /v1/items/:uuid properly' do
    expect(get: '/v1/items/123-abc').to route_to(
      format: :json,
      controller: controller,
      action: 'show',
      uuid: '123-abc'
    )
  end

  it 'routes /v1/items/:uuid/preview properly' do
    expect(get: '/v1/items/123-abc/preview').to route_to(
      format: :json,
      controller: controller,
      action: 'preview',
      uuid: '123-abc'
    )
  end

  it 'routes /v1/items/:uuid/pdf properly' do
    expect(get: '/v1/items/123-abc/pdf').to route_to(
      format: :json,
      controller: controller,
      action: 'pdf',
      uuid: '123-abc'
    )
  end

  it 'routes /v1/items/lookup/:ark properly' do
    expect(get: '/v1/items/lookup/ark:/123/456').to route_to(
      format: :json,
      controller: controller,
      action: 'lookup',
      ark: 'ark:/123/456'
    )
  end
end
