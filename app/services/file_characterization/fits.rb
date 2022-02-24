module FileCharacterization
  # Wrapper class to interact with FITS service.
  class Fits
    attr_reader :url

    def initialize(url)
      @url = url
    end

    def examine(file, **options)
      uri = URI.parse("#{url}/examine?includeStandardOutput=false")

      http = Net::HTTP.new(uri.host, uri.port)

      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form([['datafile', file]], 'multipart/form-data')

      response = http.request(request)
      response.body # TOOD: neeed to so some further cleaning to metadata
    end
  end
end
