class ForecastController < ApplicationController
  before_action :set_cache_key

  def index
    if params[:address]
      address = params[:address]
      @zip_code = fetch_zip_code(address)

      if @zip_code
        data = fetch_forecast_data(params[:address], @zip_code)
        @forecast_data = data[:forecast_data]
        @from_cache = data[:from_cache]
      else
        flash[:alert] = 'Failed to retrieve ZIP code from the provided address.'
      end
    end
  end

  private

  def set_cache_key
    @cache_key = "forecast_#{params[:address]}"
  end

  def fetch_zip_code(address)
    Geocoder.search(address)&.map(&:postal_code)&.compact.first
  end

  def fetch_forecast_data address, zip_code
    cached_forecast = Rails.cache.read(@cache_key)

    if cached_forecast
      forecast_data = JSON.parse(cached_forecast)
      from_cache = true
    else
      api_key = Rails.application.credentials.dig(:weather_api, :api_key)
      response = HTTParty.get("https://api.weatherapi.com/v1/forecast.json?key=#{api_key}&q=#{zip_code}&days=1")
      if response['error'].present? && response['error']['code'] == 1006
        response = HTTParty.get("https://api.weatherapi.com/v1/forecast.json?key=#{api_key}&q=#{address}&days=1")
      end
      forecast_data = JSON.parse(response.body)
      Rails.cache.write(@cache_key, response.body, expires_in: 30.minutes)
      from_cache = false
    end
    
    return {forecast_data: forecast_data, from_cache: from_cache}
  end
end
