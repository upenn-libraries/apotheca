# frozen_string_literal: true

# NOTE: if using subdomain constraint, get: should include full hostname,
#       and the route_to hash should include a subdomain: key
describe 'API::Resources::AssetsController', type: :routing do
  let(:controller) { 'api/resources/assets' }

  it 'routes /v1/assets/:uuid properly' do
    expect(get: '/v1/assets/123-abc').to route_to(
      format: :json,
      controller: controller,
      action: 'show',
      uuid: '123-abc'
    )
  end

  it 'routes /v1/assets/:uuid/:file properly' do
    expect(get: '/v1/assets/123-abc/thumbnail').to route_to(
      format: :json,
      controller: controller,
      action: 'file',
      uuid: '123-abc',
      file: 'thumbnail'
    )
  end
end
