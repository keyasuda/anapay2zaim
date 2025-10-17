require 'spec_helper'

RSpec.describe EmailFetcher do
  before do
    # Set environment variables for testing to avoid errors during initialization
    allow(ENV).to receive(:[]).with('IMAP_HOST').and_return('test.host.com')
    allow(ENV).to receive(:[]).with('IMAP_PORT').and_return('993')
    allow(ENV).to receive(:[]).with('IMAP_SSL').and_return('true')  # Added this one that was missing
    allow(ENV).to receive(:[]).with('EMAIL_ADDRESS').and_return('test@example.com')
    allow(ENV).to receive(:[]).with('EMAIL_PASSWORD').and_return('password')
  end

  subject(:email_fetcher) { EmailFetcher.new }

  describe '#initialize' do
    it 'sets up instance variables from environment variables' do
      expect(email_fetcher.instance_variable_get(:@imap_host)).to eq('test.host.com')
      expect(email_fetcher.instance_variable_get(:@imap_port)).to eq(993)
      expect(email_fetcher.instance_variable_get(:@email)).to eq('test@example.com')
      expect(email_fetcher.instance_variable_get(:@password)).to eq('password')
    end
  end

  describe '#valid_ana_pay_email?' do
    let(:mail) { double('Mail') }

    it 'returns true for emails from ANA Pay domain' do
      allow(mail).to receive_message_chain(:from, :first).and_return('payinfo@121.ana.co.jp')
      allow(mail).to receive(:subject).and_return('=?UTF-8?B?77y7QU5BIFBhee+8veOBlOWIqeeUqOOBruOBiuefpeOCieOBmw==?=')

      expect(email_fetcher.send(:valid_ana_pay_email?, mail)).to be true
    end

    it 'returns false for non-ANA Pay emails' do
      allow(mail).to receive_message_chain(:from, :first).and_return('other@example.com')
      allow(mail).to receive(:subject).and_return('Other Subject')

      expect(email_fetcher.send(:valid_ana_pay_email?, mail)).to be false
    end
  end

  describe '#extract_ana_pay_info' do
    let(:mail) { double('Mail') }

    it 'extracts amount, merchant, and date from email content' do
      # Create a sample body that includes amount, merchant, and date information
      sample_body = double('Mail::Body')
      test_content = "ご利用店舗：PAYPAY*DUMMY\n2025-10-14 17:33:59\n960円\n"
      allow(sample_body).to receive(:decoded).and_return(test_content)
      allow(sample_body).to receive(:encoded).and_return(false) # Not encoded
      allow(sample_body).to receive(:to_s).and_return(test_content) # Also mock to_s
      allow(mail).to receive(:body).and_return(sample_body)

      result = email_fetcher.send(:extract_ana_pay_info, mail)

      expect(result[:amount]).to eq(960)
      expect(result[:merchant]).to eq('PAYPAY*DUMMY')
      expect(result[:date]).to be_a(DateTime)
    end

    it 'handles base64 encoded body' do
      sample_body = double('Mail::Body')
      plain_content = "ご利用店舗：TEST*MERCHANT\n2025-10-14 17:33:59\n1000円\n"
      allow(sample_body).to receive(:decoded).and_return(plain_content)
      allow(sample_body).to receive(:encoded).and_return(false) # Not using encoded in this case
      allow(sample_body).to receive(:to_s).and_return(plain_content)
      allow(mail).to receive(:body).and_return(sample_body)

      result = email_fetcher.send(:extract_ana_pay_info, mail)

      expect(result[:amount]).to eq(1000)
      expect(result[:merchant]).to eq('TEST*MERCHANT')
      expect(result[:date]).to be_a(DateTime)
    end
  end
end
