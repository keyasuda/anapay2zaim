require 'net/imap'
require 'mail'
require 'date'
require 'base64'
require 'dotenv/load'
require 'active_support/core_ext/integer/time' # For n.days.ago support

# If active_support is not available, define the method
unless Integer.method_defined?(:days)
  class Integer
    def days
      self
    end

    def ago
      Date.today - self
    end

    def days_ago
      Date.today - self
    end
  end
end

class EmailFetcher
  def initialize
    @imap_host = ENV['IMAP_HOST']
    @imap_port = ENV['IMAP_PORT']&.to_i || 993
    @imap_ssl = ENV['IMAP_SSL'] != 'false'
    @email = ENV['EMAIL_ADDRESS']
    @password = ENV['EMAIL_PASSWORD']
  end

  def fetch_ana_pay_emails(since_date: 7.days.ago)
    raise "IMAP credentials not configured" unless @imap_host && @email && @password

    emails = []
    imap = Net::IMAP.new(@imap_host, port: @imap_port, ssl: @imap_ssl)
    begin
      imap.login(@email, @password)
      imap.select('INBOX')

      # Search for ANA Pay emails from the last week
      # Based on sample, ANA Pay emails come from payinfo@121.ana.co.jp
      search_criteria = [
        'FROM', 'payinfo@121.ana.co.jp',
        'SINCE', since_date.strftime('%d-%b-%Y')
      ]

      message_ids = imap.search(search_criteria)
      message_ids.each do |message_id|
        # Check if this email has already been processed (using message-id header)
        envelope = imap.fetch(message_id, 'ENVELOPE')[0].attr['ENVELOPE']
        message_id_header = get_message_id(imap, message_id)

        # For now, we'll just fetch and process all matching emails
        # In a real implementation, you'd check against a list of already processed message IDs
        raw_email = imap.fetch(message_id, 'RFC822')[0].attr['RFC822']
        mail = Mail.read_from_string(raw_email)

        # Only add if it's a valid ANA Pay transaction email
        if valid_ana_pay_email?(mail)
          emails << {
            message_id: message_id_header,
            subject: envelope.subject,
            date: envelope.date,
            body: extract_ana_pay_info(mail),
            raw: raw_email
          }
        end
      end
    ensure
      imap.disconnect if imap
    end
    emails
  end

  private

  def get_message_id(imap, message_id)
    header = imap.fetch(message_id, 'RFC822.HEADER')[0].attr['RFC822.HEADER']
    # Extract Message-ID from header
    message_id_match = header.match(/Message-ID:\s*<(.+?)>/i)
    message_id_match ? message_id_match[1] : nil
  end

  def valid_ana_pay_email?(mail)
    # Check if the email is from ANA Pay
    from = mail.from&.first&.downcase
    subject = mail.subject&.downcase

    # Common ANA Pay sender patterns based on sample
    is_ana_pay_sender = from&.include?('ana.co.jp')

    # Decode subject if it's encoded (like in the sample)
    decoded_subject = decode_subject(mail.subject)

    # Additional check in subject
    has_ana_pay_subject = decoded_subject&.include?('ANA Pay') || decoded_subject&.include?('ANAペイ')

    is_ana_pay_sender || has_ana_pay_subject
  end

  def extract_ana_pay_info(mail)
    # Extract relevant information from the email body
    # This would include amount, merchant, date, etc.
    body_text = ''

    # Handle base64 encoded body (as seen in the sample)
    if mail.body.encoded
      body_text = mail.body.decoded
    else
      body_text = mail.body.to_s
    end

    # Decode the base64 content if needed
    if body_text
      # The sample email is base64 encoded, so we need to process it
      # Extract information from the decoded body
      extracted_info = {
        raw_body: body_text,
        text_content: body_text,
        amount: extract_amount(body_text),
        merchant: extract_merchant(body_text),
        date: extract_date(body_text)
      }
    else
      extracted_info = {
        raw_body: body_text,
        text_content: body_text,
        amount: nil,
        merchant: nil,
        date: nil
      }
    end
  end

  private

  def decode_subject(subject)
    # Decode encoded subject headers
    # Sample has subject like: =?UTF-8?B?77y7QU5BIFBhee+8veOBlOWIqeeUqOOBruOBiuefpeOCieOBmw==?=
    if subject&.include?('=?UTF-8?B?')
      # Extract the base64 part
      base64_encoded = subject.match(/=\?UTF-8\?B\?(.+?)\?=/)&.captures&.first
      if base64_encoded
        begin
          decoded = Base64.decode64(base64_encoded)
          return decoded.force_encoding('UTF-8')
        rescue => e
          puts "Error decoding subject: #{e.message}"
          return subject
        end
      end
    end
    subject&.force_encoding('UTF-8') || ''
  end

  def extract_amount(body_text)
    # Look for amount pattern in the body
    # In the sample: 960円 (960 yen)
    # Ensure proper encoding before matching
    text = body_text.is_a?(String) ? body_text.force_encoding('UTF-8') : body_text.to_s.force_encoding('UTF-8')
    amount_match = text.match(/(\d+[,.\d]*)円/)
    amount_match ? amount_match[1].gsub(/[,]/, '').to_i : nil
  end

  def extract_merchant(body_text)
    # Look for merchant name pattern in the body
    # The sample shows: ご利用店舗：PAYPAY*KARATTO
    # Japanese: ご利用店舗：PAYPAY*KARATTO
    # Ensure proper encoding before matching
    text = body_text.is_a?(String) ? body_text.force_encoding('UTF-8') : body_text.to_s.force_encoding('UTF-8')
    
    # Look for the "ご利用店舗" line format from the sample
    store_match = text.match(/ご利用店舗[：:]([^\r\n]+)/)
    if store_match
      merchant_name = store_match[1]
      # Clean up the merchant name - remove any extra characters
      return merchant_name.strip
    end
    
    # Additional fallback for other potential formats
    # The sample might also contain "加盟店名：..." pattern
    line_match = text.match(/加盟店名[：:]([^\r\n]+)/)
    if line_match
      return line_match[1].strip
    end
    
    # Try the previous pattern as another fallback
    merchant_match = text.match(/PAYPAY\*?\(?([^\)]+)\)?\s*円?/)
    if merchant_match
      merchant_name = merchant_match[1]
      return merchant_name.strip
    end
    
    nil
  end

  def extract_date(body_text)
    # Look for transaction date in the body
    # Sample format: "2025-10-14 17:33:59"
    text = body_text.is_a?(String) ? body_text.force_encoding('UTF-8') : body_text.to_s.force_encoding('UTF-8')
    date_match = text.match(/(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})/)
    if date_match
      DateTime.parse(date_match[1])
    else
      # Try alternative format from email header
      nil
    end
  end
end

# Example usage:
# fetcher = EmailFetcher.new
# emails = fetcher.fetch_ana_pay_emails(since_date: Date.today - 7)
# puts "Found #{emails.length} ANA Pay emails"
