require_relative 'lib/email_fetcher'
require 'date'

# Main application to fetch ANA Pay emails and process them
def main
  puts "Starting ANAPay2Zaim email fetching process..."
  
  fetcher = EmailFetcher.new
  emails = fetcher.fetch_ana_pay_emails(since_date: Date.today - 7)
  
  puts "Found #{emails.length} ANA Pay emails from the last 7 days"
  
  emails.each do |email|
    puts "Processing email: #{email[:subject]}"
    puts "Date: #{email[:date]}"
    puts "Message ID: #{email[:message_id]}"
    puts "Amount: #{email[:body][:amount]}"
    puts "Merchant: #{email[:body][:merchant]}"
    puts "Transaction Date: #{email[:body][:date]}"
    puts "-" * 50
  end
  
  puts "Email fetching process completed."
rescue => e
  puts "Error occurred: #{e.message}"
  puts e.backtrace
end

main if __FILE__ == $0