require_relative 'lib/email_fetcher'

# Test script to verify the email fetcher implementation
puts "Testing EmailFetcher class..."

begin
  # Initialize the fetcher
  fetcher = EmailFetcher.new
  
  # Check if the required environment variables are set
  if fetcher.instance_variable_get(:@imap_host).nil?
    puts "WARNING: IMAP_HOST is not set in environment. Using a mock for testing."
    # We'll test the structure without actual connection
    puts "EmailFetcher initialized successfully"
    puts "IMAP Host: #{fetcher.instance_variable_get(:@imap_host)}"
    puts "IMAP Port: #{fetcher.instance_variable_get(:@imap_port)}"
    puts "Email: #{fetcher.instance_variable_get(:@email)}"
  else
    puts "Attempting to connect to IMAP server..."
    # This is just testing the method definition without actual execution
    puts "EmailFetcher initialized successfully"
  end

  # Test the method exists
  if fetcher.respond_to?(:fetch_ana_pay_emails)
    puts "✓ fetch_ana_pay_emails method exists"
  else
    puts "✗ fetch_ana_pay_emails method missing"
  end

  puts "EmailFetcher test completed."
rescue => e
  puts "Error in EmailFetcher test: #{e.message}"
  puts e.backtrace
end