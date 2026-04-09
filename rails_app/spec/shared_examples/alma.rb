# frozen_string_literal: true

# Stub request for successful Alma request.
shared_context 'with successful Alma request' do
  let(:bibnumber) { MMSIDValidator::EXAMPLE_VALID_MMS_ID }

  before do
    url = URI::HTTPS.build(host: Settings.alma.host, path: "#{Settings.alma.bibs.path}/#{bibnumber}",
                           query: { expand: 'p_avail', format: 'json' }.to_query)
    stub_request(:get, url).to_return(status: 200, body: alma_bibs_json(bibnumber, xml), headers: {})
  end
end

# Stub request for unsuccessful Alma request.
shared_context 'with unsuccessful Alma request' do
  let(:bibnumber) { MMSIDValidator::EXAMPLE_VALID_MMS_ID }

  before do
    url = URI::HTTPS.build(host: Settings.alma.host, path: "#{Settings.alma.bibs.path}/#{bibnumber}",
                           query: { expand: 'p_avail', format: 'json' }.to_query)
    stub_request(:get, url).to_return(status: 500, body: alma_bibs_error, headers: {})
  end
end

# @param marcxml [String]
# @return [String]
def alma_bibs_json(bibnumber, marcxml)
  JSON.generate({ 'mms_id': bibnumber, 'anies': [marcxml] })
end

def alma_bibs_error
  JSON.generate({
                  errorsExist: true,
                  errorList: { error: [{ errorCode: '401652', errorMessage: 'General Error - An error has occurred' }] }
                })
end
