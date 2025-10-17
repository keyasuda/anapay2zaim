require 'oauth'
require 'json'
require 'uri'
require 'net/http'

class ZaimApiClient
  def initialize
    @consumer_key = ENV['ZAIM_CONSUMER_ID']
    @consumer_secret = ENV['ZAIM_CONSUMER_SECRET']
    
    # Load access tokens
    if File.exist?('zaim_tokens.json')
      tokens = JSON.parse(File.read('zaim_tokens.json'))
      @access_token = tokens['access_token']
      @access_token_secret = tokens['access_token_secret']
    else
      raise "zaim_tokens.json file not found. Please run token acquisition script first."
    end
    
    raise "ZAIM_CONSUMER_ID and ZAIM_CONSUMER_SECRET must be set in environment" unless @consumer_key && @consumer_secret
    
    @consumer = OAuth::Consumer.new(@consumer_key, @consumer_secret, {
      site: 'https://api.zaim.net',
      request_token_path: '/v2/auth/request',
      authorize_path: '/users/auth',
      access_token_path: '/v2/auth/access'
    })
    
    @access_token_obj = OAuth::AccessToken.new(@consumer, @access_token, @access_token_secret)
  end

  def get_user_verify
    url = URI('https://api.zaim.net/v2/home/user/verify')
    response = @access_token_obj.request(:get, url.to_s)
    
    if response.code == '200'
      JSON.parse(response.body)
    else
      raise "Error getting user verification: #{response.code} - #{response.body}"
    end
  end

  def get_genres
    url = URI('https://api.zaim.net/v2/home/genre?mapping=1')
    response = @access_token_obj.request(:get, url.to_s)
    
    if response.code == '200'
      JSON.parse(response.body)
    else
      raise "Error getting genres: #{response.code} - #{response.body}"
    end
  end

  def get_categories
    url = URI('https://api.zaim.net/v2/home/category?mapping=1')
    response = @access_token_obj.request(:get, url.to_s)
    
    if response.code == '200'
      JSON.parse(response.body)
    else
      raise "Error getting categories: #{response.code} - #{response.body}"
    end
  end

  def create_payment(params)
    url = URI('https://api.zaim.net/v2/home/money/payment')
    
    # Prepare the parameters
    request_params = {
      mapping: 1,
      amount: params[:amount],
      date: params[:date],
      genre_id: params[:genre_id],
      category_id: params[:category_id] || 101, # Default to '食料品' if not specified
      place: params[:place] || params[:merchant],
      name: params[:name] || params[:merchant]
    }
    
    # Add optional parameters
    request_params[:comment] = params[:comment] if params[:comment]
    request_params[:from_account_id] = params[:from_account_id] if params[:from_account_id]

    response = @access_token_obj.request(:post, url.to_s, request_params)
    
    if response.code == '200'
      JSON.parse(response.body)
    else
      raise "Error creating payment: #{response.code} - #{response.body}"
    end
  end
end