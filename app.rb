require_relative 'lib/anapay_to_zaim'
require 'date'

# Main application to fetch ANA Pay emails and register them to Zaim
def main
  puts "Starting ANAPay2Zaim email fetching and registration process..."
  
  processor = ANAPayToZaim.new
  results = processor.process_emails(since_date: Date.today - 7)
  
  puts "\nProcessing Summary:"
  puts "Processed: #{results[:processed]} emails"
  puts "Registered: #{results[:registered]} transactions"
  puts "Errors: #{results[:errors]} transactions"
  
  puts "Email fetching and registration process completed."
rescue => e
  puts "Error occurred: #{e.message}"
  puts e.backtrace
end

main if __FILE__ == $0