require 'spec_helper'

RSpec.describe ANAPayToZaim do
  let(:email_fetcher) { instance_double(EmailFetcher) }
  let(:zaim_client) { instance_double(ZaimApiClient) }

  before do
    # Set up environment variables to avoid errors during class initialization
    allow(ENV).to receive(:[]).with('IMAP_HOST').and_return('test.host.com')
    allow(ENV).to receive(:[]).with('IMAP_PORT').and_return('993')
    allow(ENV).to receive(:[]).with('IMAP_SSL').and_return('true')  # Needed for EmailFetcher
    allow(ENV).to receive(:[]).with('EMAIL_ADDRESS').and_return('test@example.com')
    allow(ENV).to receive(:[]).with('EMAIL_PASSWORD').and_return('password')
    allow(ENV).to receive(:[]).with('ZAIM_CONSUMER_ID').and_return('test_consumer_id')
    allow(ENV).to receive(:[]).with('ZAIM_CONSUMER_SECRET').and_return('test_consumer_secret')
    allow(ENV).to receive(:[]).with('ZAIM_DEFAULT_FROM_ACCOUNT_ID').and_return('20433200')

    # Mock file existence for merchant mapping
    allow(File).to receive(:exist?).with('merchant_mapping.yml').and_return(true)
    allow(YAML).to receive(:load_file).with('merchant_mapping.yml').and_return({})

    # Mock file existence for processed emails log
    allow(File).to receive(:exist?).with('processed_emails.log').and_return(true)
    allow(File).to receive(:readlines).with('processed_emails.log').and_return([])

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

      # Mock the file operations for processed email tracking
      allow(File).to receive(:exist?).with('processed_emails.log').and_return(true)
      allow(File).to receive(:readlines).with('processed_emails.log').and_return([])
      file_double = double('file')
      allow(file_double).to receive(:puts)
      allow(File).to receive(:open).with('processed_emails.log', 'a').and_yield(file_double)

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

      # Mock the file operations for processed email tracking
      allow(File).to receive(:exist?).with('processed_emails.log').and_return(true)
      allow(File).to receive(:readlines).with('processed_emails.log').and_return([])
      # Note: We don't expect file to be opened since the registration will fail

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

  describe 'merchant mapping' do
    let(:sample_email_with_mapping) do
      [{
        subject: 'Test Subject',
        date: 'Tue, 14 Oct 2025 17:34:39 +0900 (JST)',
        message_id: '123456',
        body: {
          amount: 960,
          merchant: 'PAYPAY*DUMMY',
          date: DateTime.new(2025, 10, 14, 17, 33, 59)
        }
      }]
    end

    let(:merchant_mapping) do
      {
        'PAYPAY*DUMMY' => {
          'merchant' => '店舗1',
          'category_id' => 101,
          'genre_id' => 10101
        }
      }
    end

    it 'uses custom merchant mapping when available' do
      since_date = Date.today - 7
      # Mock email fetching
      allow(email_fetcher).to receive(:fetch_ana_pay_emails).with(since_date: since_date).and_return(sample_email_with_mapping)

      # Mock merchant mapping
      allow(File).to receive(:exist?).with('merchant_mapping.yml').and_return(true)
      allow(YAML).to receive(:load_file).with('merchant_mapping.yml').and_return(merchant_mapping)

      # Mock the file operations for processed email tracking
      allow(File).to receive(:exist?).with('processed_emails.log').and_return(true)
      allow(File).to receive(:readlines).with('processed_emails.log').and_return([])
      file_double = double('file')
      allow(file_double).to receive(:puts)
      allow(File).to receive(:open).with('processed_emails.log', 'a').and_yield(file_double)

      # Mock Zaim API call
      zaim_response = {
        "money"=>{"id"=>9304094510, "modified"=>"2025-10-18 00:33:02"},
        "user"=>{"data_modified"=>"2025-10-18 00:33:02", "day_count"=>562, "input_count"=>3443, "repeat_count"=>3},
        "banners"=>[],
        "stamps"=>nil,
        "place"=>{"id"=>408099440, "name"=>"店舗1"},
        "requested"=>1760715182
      }
      expect(zaim_client).to receive(:create_payment).with(
        hash_including(
          amount: 960,
          date: '2025-10-14',
          genre_id: 10101,  # Custom genre from mapping
          category_id: 101,  # Custom category from mapping
          merchant: '店舗1',  # Custom merchant from mapping
          comment: 'ANA Pay transaction: PAYPAY*DUMMY'
        )
      ).and_return(zaim_response)

      # Create a new instance to use the mocked mapping
      test_instance = ANAPayToZaim.new
      allow(EmailFetcher).to receive(:new).and_return(email_fetcher)
      allow(ZaimApiClient).to receive(:new).and_return(zaim_client)
      allow(test_instance).to receive(:instance_variable_get).with(:@email_fetcher).and_return(email_fetcher)
      allow(test_instance).to receive(:instance_variable_get).with(:@zaim_client).and_return(zaim_client)
      # Mock the file operations for processed email tracking
      allow(File).to receive(:exist?).with('processed_emails.log').and_return(true)
      allow(File).to receive(:readlines).with('processed_emails.log').and_return([])
      file_double = double('file')
      allow(file_double).to receive(:puts)
      allow(File).to receive(:open).with('processed_emails.log', 'a').and_yield(file_double)

      results = test_instance.process_emails(since_date: since_date)

      expect(results[:processed]).to eq(1)
      expect(results[:registered]).to eq(1)
      expect(results[:errors]).to eq(0)
    end

    it 'uses defaults when no mapping is available' do
      since_date = Date.today - 7
      # Create a sample email for this specific test
      sample_email_local = [{
        subject: 'Test Subject',
        date: 'Tue, 14 Oct 2025 17:34:39 +0900 (JST)',
        message_id: '123456',
        body: {
          amount: 960,
          merchant: 'Test Merchant',
          date: DateTime.new(2025, 10, 14, 17, 33, 59)
        }
      }]

      # Mock email fetching with merchant not in mapping
      allow(email_fetcher).to receive(:fetch_ana_pay_emails).with(since_date: since_date).and_return(sample_email_local)

      # Mock empty mapping
      allow(File).to receive(:exist?).with('merchant_mapping.yml').and_return(true)
      allow(YAML).to receive(:load_file).with('merchant_mapping.yml').and_return({})

      # Mock the file operations for processed email tracking
      allow(File).to receive(:exist?).with('processed_emails.log').and_return(true)
      allow(File).to receive(:readlines).with('processed_emails.log').and_return([])
      file_double = double('file')
      allow(file_double).to receive(:puts)
      allow(File).to receive(:open).with('processed_emails.log', 'a').and_yield(file_double)

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
          genre_id: ANAPayToZaim::DEFAULT_GENRE_ID,  # Default genre
          category_id: ANAPayToZaim::DEFAULT_CATEGORY_ID,  # Default category
          merchant: 'Test Merchant',  # Original merchant
          comment: 'ANA Pay transaction: Test Merchant'
        )
      ).and_return(zaim_response)

      # Create a new instance to use the mocked mapping
      test_instance = ANAPayToZaim.new
      allow(EmailFetcher).to receive(:new).and_return(email_fetcher)
      allow(ZaimApiClient).to receive(:new).and_return(zaim_client)
      allow(test_instance).to receive(:instance_variable_get).with(:@email_fetcher).and_return(email_fetcher)
      allow(test_instance).to receive(:instance_variable_get).with(:@zaim_client).and_return(zaim_client)
      # Mock the file operations for processed email tracking
      allow(File).to receive(:exist?).with('processed_emails.log').and_return(true)
      allow(File).to receive(:readlines).with('processed_emails.log').and_return([])
      file_double = double('file')
      allow(file_double).to receive(:puts)
      allow(File).to receive(:open).with('processed_emails.log', 'a').and_yield(file_double)

      results = test_instance.process_emails(since_date: since_date)

      expect(results[:processed]).to eq(1)
      expect(results[:registered]).to eq(1)
      expect(results[:errors]).to eq(0)
    end
  end
end
