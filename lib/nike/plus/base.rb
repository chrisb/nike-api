module Nike
  module Plus
    class Base

      include ActiveSupport::Configurable

      config.domain           = 'nikeplus.nike.com'
      config.secure_domain    = 'secure-nikeplus.nike.com'
      config.api_domain       = 'api.nike.com'

      config.format           = 'json'
      config.email            = nil
      config.password         = nil
      config.app              = 'b31990e7-8583-4251-808f-9dc67b40f5d2'
      config.endpoints        = {
        :login      => { :path => '/nsl/services/user/login', :protocol => :secure, :domain => :secure },
        :activities => { :path => '/plus/activity/running/:screen_name/lifetime/activities' }
        :summary    => { :path => '/v1.0/me/activities/summary/:start_date', :domain => :api }
      }

      attr_accessor :user, :cookie

      def url(endpoint)
        endpoint = config.endpoints[endpoint.to_sym]
        protocol = endpoint[:protocol] == :secure ? 'https' : 'http'
        domain   = config.send("#{endpoint[:domain].present? ? endpoint[:domain].to_s+'_' : ''}domain")
        path     = endpoint[:path].dup.gsub( ':screen_name', screen_name.to_s )

        return "#{protocol}://#{domain}#{path}"
      end

      def screen_name
        user.present? ? user['screenName'] : nil
      end

      def successful_response?(response)
        response['header']['success'] == 'true'
      end

      def response_error(response)
        "#{response['header']['errorCodes'].first['code']} exception: #{response['header']['errorCodes'].first['message']}"
      end

      def get(endpoint,params)
        response = Typhoeus::Request.get(
          self.url(endpoint), 
          :params  => { :app => config.app, :format => config.format, :'contentType' => 'plaintext' }.merge(params),
          :headers => { 'Cookie' => self.cookie })
        JSON.parse(response.body)
      end

      def post(endpoint,params)
        puts self.url(endpoint).inspect
        response = Typhoeus::Request.post(
          self.url(endpoint), 
          :params => { :app => config.app, :format => config.format, :'contentType' => 'plaintext' }.merge(params))
      end

      def activities
        get :activities, { :indexStart => '999999', :indexEnd => '1000000' }
      end

      def initialize
        response      = post( :login, { :email => config.email, :password => config.password })
        response_hash = JSON.parse(response.body)['serviceResponse']

        raise response_error(response_hash) unless successful_response?(response_hash)

        self.cookie = response.headers_hash['Set-Cookie'][0].split('; ').first
        self.user   = response_hash['body']['User']
      end

    end
  end
end