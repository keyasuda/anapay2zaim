require 'spec_helper'

RSpec.describe ANAPayToZaim do
  let(:email_fetcher) { instance_double(EmailFetcher) }
  let(:zaim_client) { instance_double(ZaimApiClient) }

  before do
    # Set up environment variables to avoid errors during class initialization
    allow(ENV).to receive(:[]).with('IMAP_HOST').and_return('test.host.com')
    allow(ENV).to receive(:[]).with('IMAP_PORT').and_return('993')
    allow(ENV).to receive(:[]).with('EMAIL_ADDRESS').and_return('test@example.com')
    allow(ENV).to receive(:[]).with('EMAIL_PASSWORD').and_return('password')
    allow(ENV).to receive(:[]).with('ZAIM_CONSUMER_ID').and_return('test_consumer_id')
    allow(ENV).to receive(:[]).with('ZAIM_CONSUMER_SECRET').and_return('test_consumer_secret')
    
    # Mock file existence for token file
    allow(File).to receive(:exist?).with('zaim_tokens.json').and_return(true)
    allow(File).to receive(:read).with('zaim_tokens.json').and_return('{"access_token": "test", "access_token_secret": "test"}')
    
    # Stub the initialization to use our test doubles
    allow(EmailFetcher).to receive(:new).and_return(email_fetcher)
    allow(ZaimApiClient).to receive(:new).and_return(zaim_client)
  end

  subject(:anapay_to_zaim) { ANAPayToZaim.new }

  describe '#process_emails' do
    let(:sample_email) do
      [{
        subject: 'Test Subject',
        date: 'Tue, 14 Oct 2025 17:34:39 +0900 (JST)',
        message_id: '123456',
        body: {
          amount: 960,
          merchant: 'Test Merchant',
          date: DateTime.new(2025, 10, 14, 17, 33, 59)
        }
      }]
    end

    it 'fetches emails and registers them to Zaim' do
      since_date = Date.today - 7
      # Mock email fetching
      allow(email_fetcher).to receive(:fetch_ana_pay_emails).with(since_date: since_date).and_return(sample_email)

      # Mock Zaim API call
      zaim_response = {
        "money"=>{"id"=>9304094510, "modified"=>"2025-10-18 00:33:02"},
        "user"=>{"data_modified"=>"2025-10-18 00:33:02", "day_count"=>562, "input_count"=>3443, "repeat_count"=>3},
        "banners"=>[],
        "stamps"=>nil,
        "place"=>{"id"=>408099440, "name"=>"Test Merchant"},
        "requested"=>1760715182
      }
      expect(zaim_client).to receive(:create_payment).with(
        hash_including(
          amount: 960,
          date: '2025-10-14',
          genre_id: ANAPayToZaim::DEFAULT_GENRE_ID,
          category_id: ANAPayToZaim::DEFAULT_CATEGORY_ID,
          merchant: 'Test Merchant',
          comment: 'ANA Pay transaction: Test Merchant'
        )
      ).and_return(zaim_response)

      # Run the process
      results = anapay_to_zaim.process_emails(since_date: since_date)

      # Verify results
      expect(results[:processed]).to eq(1)
      expect(results[:registered]).to eq(1)
      expect(results[:errors]).to eq(0)
    end

    it 'handles emails with missing information gracefully' do
      incomplete_email = [{
        subject: 'Test Subject',
        date: 'Tue, 14 Oct 2025 17:34:39 +0900 (JST)',
        message_id: '123456',
        body: {
          amount: nil,  # Missing amount
          merchant: 'Test Merchant',
          date: DateTime.new(2025, 10, 14, 17, 33, 59)
        }
      }]

      since_date = Date.today - 7
      allow(email_fetcher).to receive(:fetch_ana_pay_emails).with(since_date: since_date).and_return(incomplete_email)

      # Should not attempt to call Zaim API for incomplete email
      expect(zaim_client).not_to receive(:create_payment)

      results = anapay_to_zaim.process_emails(since_date: since_date)

      expect(results[:processed]).to eq(1)
      expect(results[:errors]).to eq(1)
    end
  end

  describe 'constants' do
    it 'has correct default genre and category IDs' do
      expect(ANAPayToZaim::DEFAULT_GENRE_ID).to eq(19905)  # 未分類
      expect(ANAPayToZaim::DEFAULT_CATEGORY_ID).to eq(199) # 共通
    end
  end
end