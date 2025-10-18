require 'oauth'
require 'json'
require 'uri'
require 'net/http'
require 'dotenv/load'

class AccountRetriever
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
      site: 'https://api.zaim.net'
    })
    
    @access_token_obj = OAuth::AccessToken.new(@consumer, @access_token, @access_token_secret)
  end

  def retrieve_and_save_accounts
    puts "Retrieving accounts from Zaim API..."

    # Prepare API call
    url = URI('https://api.zaim.net/v2/home/account?mapping=1')

    # Make the API call using the correct request method
    response = @access_token_obj.request(:get, url.to_s)
    
    if response.code == '200'
      accounts_data = JSON.parse(response.body)
      
      # Save accounts to file
      File.write('zaim_accounts.json', JSON.pretty_generate(accounts_data['accounts']))
      
      puts "Accounts successfully retrieved and saved to zaim_accounts.json"
      puts "Number of accounts retrieved: #{accounts_data['accounts'].length}"
      
      # Display information about the accounts
      accounts_data['accounts'].each do |account|
        puts "ID: #{account['id']}, Name: #{account['name']}, Sort: #{account['sort']}"
      end
    else
      puts "Error retrieving accounts: #{response.code} - #{response.body}"
      raise "Failed to retrieve accounts from Zaim API"
    end
  end
end

if __FILE__ == $0
  begin
    retriever = AccountRetriever.new
    retriever.retrieve_and_save_accounts
  rescue => e
    puts "Error: #{e.message}"
  end
end