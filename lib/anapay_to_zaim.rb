require_relative 'email_fetcher'
require_relative 'zaim_api_client'
require 'date'

class ANAPayToZaim
  # Using Genre ID: 19905, Name: 未分類, Category ID: 199 as specified
  DEFAULT_GENRE_ID = 19905
  DEFAULT_CATEGORY_ID = 199

  def initialize
    @email_fetcher = EmailFetcher.new
    @zaim_client = ZaimApiClient.new
  end

  def process_emails(since_date: 7.days.ago)
    emails = @email_fetcher.fetch_ana_pay_emails(since_date: since_date)
    
    results = {
      processed: 0,
      registered: 0,
      errors: 0
    }
    
    puts "Found #{emails.length} ANA Pay emails from the last 7 days"
    
    emails.each do |email|
      results[:processed] += 1
      
      puts "Processing email: #{email[:subject]}"
      puts "Date: #{email[:date]}"
      puts "Message ID: #{email[:message_id]}"
      puts "Amount: #{email[:body][:amount]}"
      puts "Merchant: #{email[:body][:merchant]}"
      puts "Transaction Date: #{email[:body][:date]}"
      puts
      
      if register_email_to_zaim(email)
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

  def register_email_to_zaim(email)
    return false unless email[:body][:amount] && email[:body][:merchant]

    begin
      # Format the transaction date for Zaim API
      zaim_date = determine_date(email)
      
      payment_params = {
        amount: email[:body][:amount],
        date: zaim_date,
        genre_id: DEFAULT_GENRE_ID,  # 未分類
        category_id: DEFAULT_CATEGORY_ID, # 共通
        merchant: email[:body][:merchant],
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