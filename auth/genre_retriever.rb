require 'oauth'
require 'json'
require 'uri'
require 'net/http'
require 'dotenv/load'

class GenreRetriever
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

  def retrieve_and_save_genres
    puts "Retrieving genres from Zaim API..."

    # Prepare API call
    url = URI('https://api.zaim.net/v2/home/genre?mapping=1')

    # Make the API call - using the proper approach for GET request with OAuth
    response = @access_token_obj.request(:get, url.to_s)
    
    if response.code == '200'
      genres_data = JSON.parse(response.body)
      
      # Save genres to file
      File.write('zaim_genres.json', JSON.pretty_generate(genres_data['genres']))
      
      puts "Genres successfully retrieved and saved to zaim_genres.json"
      puts "Number of genres retrieved: #{genres_data['genres'].length}"
      
      # Display some information about the genres
      genres_data['genres'].each do |genre|
        puts "ID: #{genre['id']}, Name: #{genre['name']}, Category ID: #{genre['category_id']}"
      end
    else
      puts "Error retrieving genres: #{response.code} - #{response.body}"
      raise "Failed to retrieve genres from Zaim API"
    end
  end
end

if __FILE__ == $0
  begin
    retriever = GenreRetriever.new
    retriever.retrieve_and_save_genres
  rescue => e
    puts "Error: #{e.message}"
  end
end