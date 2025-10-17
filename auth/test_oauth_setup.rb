require 'oauth'
require 'json'
require 'uri'
require 'net/http'
require 'dotenv/load'

# Test if environment variables are properly loaded
puts "ZAIM_CONSUMER_ID: #{ENV['ZAIM_CONSUMER_ID'] ? 'SET' : 'NOT SET'}"
puts "ZAIM_CONSUMER_SECRET: #{ENV['ZAIM_CONSUMER_SECRET'] ? 'SET' : 'NOT SET'}"

if ENV['ZAIM_CONSUMER_ID'] && ENV['ZAIM_CONSUMER_SECRET']
  consumer = OAuth::Consumer.new(
    ENV['ZAIM_CONSUMER_ID'], 
    ENV['ZAIM_CONSUMER_SECRET'], 
    {
      site: 'https://api.zaim.net',
      request_token_path: '/v2/auth/request',
      authorize_path: '/users/auth',
      access_token_path: '/v2/auth/access'
    }
  )
  
  puts "OAuth consumer created successfully"
  puts "Consumer key: #{ENV['ZAIM_CONSUMER_ID']}"
  puts "Consumer secret: #{ENV['ZAIM_CONSUMER_SECRET'][0..10]}..." # Only show partial secret for security
  
  # Test getting request token
  begin
    request_token = consumer.get_request_token
    puts "Request token obtained: #{request_token.token[0..10]}..." # Only show partial token for security
    puts "Request token secret: #{request_token.secret[0..10]}..." # Only show partial secret for security
    puts "Full authorization URL: https://auth.zaim.net/users/auth?oauth_token=#{request_token.token}"
    puts "\n"
    puts "To complete the OAuth flow:"
    puts "1. Visit the authorization URL above"
    puts "2. Log in to Zaim and authorize the application"
    puts "3. You'll be redirected to a URL containing an oauth_verifier parameter"
    puts "4. Run auth/token_acquirer.rb again and enter the oauth_verifier when prompted"
  rescue => e
    puts "Error getting request token: #{e.message}"
    puts e.backtrace
  end
else
  puts "Please set ZAIM_CONSUMER_ID and ZAIM_CONSUMER_SECRET in your .env file"
end