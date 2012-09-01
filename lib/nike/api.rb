module Nike
  class API

    include ActiveSupport::Configurable

    config.device_id    = nil
    config.access_token = nil
    
    config.appid        = 'fuelband'
    config.accept       = 'application/json'
    config.content_type = 'application/json'
    config.debug        = false
    config.domain       = 'api.nike.com'

    config.endpoints = {
      :summary => '/v1.0/me/activities/summary/:start_date'
    }

    def url(endpoint,params={})
      endpoint = config.endpoints[endpoint.to_sym]
      path     = endpoint.dup
      params.keys.each { |key| path.gsub!(":#{key}",params[key].to_s) }
      return "https://#{config.domain}#{path}"
    end

    def headers
      { 'Accept' => config.accept, 'Content-Type' => config.content_type, 'appid' => config.appid }
    end

    def get(endpoint,params={})
      params   = params.inject({}) { |m,i| m[i.first] = i.last.is_a?(Date) ? i.last.strftime('%d%m%y') : i.last; m } # replace dates with their string equivalents
      response = Typhoeus::Request.get(
        self.url(endpoint,params), 
        :params  => { :access_token => config.access_token, :'deviceId' => config.device_id }.merge(params),
        :headers => headers,
        :verbose => config.debug )
      JSON.parse(response.body)
    end

    #
    # methods to send data to Nike
    #

    # imprint
    # get-access-token
    # sync
    # get-sync-params
    # one-time-token
    # get-device-prefs
    # get-device-info
    # get-profile
    # set-profile
    # refresh-access-token
    # get-daily-goal
    # create-daily-goal
    # update-daily-goal
    # list-daily-goals
    # reset-last-sync-offset
    # get-events
    # ack-event
    # ack-all-events

    def initialize
    end

    def summary(start_date,end_date,fidelity=96)
      get :summary, { :start_date => start_date, :'endDate' => end_date, :fidelity => fidelity }
    end

  end
end