require 'oauth'
require 'json'
require 'uri'
require 'net/http'
require 'dotenv/load'

class TokenAcquirer
  REQUEST_TOKEN_URL = 'https://api.zaim.net/v2/auth/request'
  AUTHORIZE_URL = 'https://auth.zaim.net/users/auth'
  ACCESS_TOKEN_URL = 'https://api.zaim.net/v2/auth/access'

  def initialize
    @consumer_key = ENV['ZAIM_CONSUMER_ID']
    @consumer_secret = ENV['ZAIM_CONSUMER_SECRET']
    
    raise "ZAIM_CONSUMER_ID and ZAIM_CONSUMER_SECRET must be set in environment" unless @consumer_key && @consumer_secret
    
    @consumer = OAuth::Consumer.new(@consumer_key, @consumer_secret, {
      site: 'https://api.zaim.net',
      request_token_path: '/v2/auth/request',
      authorize_path: '/users/auth',
      access_token_path: '/v2/auth/access'
    })
  end

  def acquire_and_save_tokens
    puts "Starting Zaim OAuth token acquisition process..."

    # Step 1: Get request token
    request_token = @consumer.get_request_token
    puts "Request token obtained."

    # Step 2: Authorize URL
    # According to Zaim API documentation, authorization URL should be:
    # https://auth.zaim.net/users/auth
    authorize_url = "https://auth.zaim.net/users/auth?oauth_token=#{request_token.token}"
    puts "Please visit the following URL to authorize the application:"
    puts authorize_url
    puts "After authorizing, you will be redirected to a URL containing oauth_verifier parameter."

    # Step 3: Get verifier from user input
    print "Enter the oauth_verifier from the redirect URL: "
    oauth_verifier = gets.chomp

    # Step 4: Get access token
    access_token = request_token.get_access_token(oauth_verifier: oauth_verifier)
    
    # Step 5: Save tokens to file
    tokens_data = {
      access_token: access_token.token,
      access_token_secret: access_token.secret
    }
    
    File.write('zaim_tokens.json', JSON.pretty_generate(tokens_data))
    
    puts "Access tokens successfully acquired and saved to zaim_tokens.json"
    puts "You can now use these tokens to make API calls to Zaim."
    puts "Remember to keep this file secure as it contains sensitive credentials."
  end
end

if __FILE__ == $0
  acquirer = TokenAcquirer.new
  acquirer.acquire_and_save_tokens
end