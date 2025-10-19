require_relative 'email_fetcher'
require_relative 'zaim_api_client'
require 'date'
require 'yaml'

class ANAPayToZaim
  # Using Genre ID: 19905, Name: 未分類, Category ID: 199 as specified
  DEFAULT_GENRE_ID = 19905
  DEFAULT_CATEGORY_ID = 199

  def initialize
    @email_fetcher = EmailFetcher.new
    @zaim_client = ZaimApiClient.new
    @merchant_mapping = load_merchant_mapping
  end

  def process_emails(since_date: 7.days.ago)
    # Load previously processed message IDs
    processed_message_ids = load_processed_message_ids
    
    emails = @email_fetcher.fetch_ana_pay_emails(since_date: since_date)
    
    # Filter out emails that have already been processed
    new_emails = emails.reject { |email| processed_message_ids.include?(email[:message_id]) }
    
    results = {
      processed: 0,
      registered: 0,
      errors: 0
    }
    
    puts "Found #{emails.length} ANA Pay emails from the last 7 days"
    puts "#{new_emails.length} of them are new (not yet processed)"
    
    new_emails.each do |email|
      results[:processed] += 1
      
      puts "Processing email: #{email[:subject]}"
      puts "Date: #{email[:date]}"
      puts "Message ID: #{email[:message_id]}"
      puts "Amount: #{email[:body][:amount]}"
      puts "Merchant: #{email[:body][:merchant]}"
      puts "Transaction Date: #{email[:body][:date]}"
      puts
      
      if register_email_to_zaim(email)
        # Log the message ID after successful registration
        log_processed_message_id(email[:message_id])
        results[:registered] += 1
        puts "Successfully registered to Zaim"
      else
        results[:errors] += 1
        puts "Failed to register to Zaim"
      end
      
      puts "-" * 50
    end
    
    results
  end

  private

  def load_merchant_mapping
    mapping_file = 'merchant_mapping.yml'
    if File.exist?(mapping_file)
      YAML.load_file(mapping_file) || {}
    else
      {}
    end
  end

  def load_processed_message_ids
    log_file = 'processed_emails.log'
    if File.exist?(log_file)
      File.readlines(log_file).map(&:chomp).reject(&:empty?)
    else
      []
    end
  end

  def log_processed_message_id(message_id)
    File.open('processed_emails.log', 'a') do |file|
      file.puts(message_id)
    end
  end

  def register_email_to_zaim(email)
    return false unless email[:body][:amount] && email[:body][:merchant]

    begin
      # Format the transaction date for Zaim API
      zaim_date = determine_date(email)
      
      # Get merchant mapping if exists
      mapping = @merchant_mapping[email[:body][:merchant]]
      
      # Set parameters, using mapping if available
      genre_id = mapping ? mapping['genre_id'] : DEFAULT_GENRE_ID
      category_id = mapping ? mapping['category_id'] : DEFAULT_CATEGORY_ID
      merchant_name = mapping ? mapping['merchant'] : email[:body][:merchant]
      
      payment_params = {
        amount: email[:body][:amount],
        date: zaim_date,
        genre_id: genre_id,
        category_id: category_id,
        merchant: merchant_name,
        comment: "ANA Pay transaction: #{email[:body][:merchant]}"
      }
      
      result = @zaim_client.create_payment(payment_params)
      puts "Zaim API response: #{result}"
      true
    rescue => e
      puts "Error registering to Zaim: #{e.message}"
      false
    end
  end
  
  def determine_date(email)
    if email[:body][:date]
      email[:body][:date].strftime('%Y-%m-%d')
    elsif email[:date]
      Date.parse(email[:date].to_s).strftime('%Y-%m-%d')
    else
      Date.today.strftime('%Y-%m-%d')
    end
  end
end