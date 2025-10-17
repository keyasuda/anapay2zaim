require 'spec_helper'

RSpec.describe ZaimApiClient do
  before do
    # Mock that zaim_tokens.json exists with test data
    test_tokens = {
      'access_token' => 'test_access_token',
      'access_token_secret' => 'test_access_token_secret'
    }
    allow(File).to receive(:exist?).with('zaim_tokens.json').and_return(true)
    allow(File).to receive(:read).with('zaim_tokens.json').and_return(test_tokens.to_json)

    # Set environment variables for testing
    allow(ENV).to receive(:[]).with('ZAIM_CONSUMER_ID').and_return('test_consumer_id')
    allow(ENV).to receive(:[]).with('ZAIM_CONSUMER_SECRET').and_return('test_consumer_secret')
    # Also need to allow other environment variables that might be accessed
    allow(ENV).to receive(:[]).and_call_original # Allow all other ENV access but return nil by default
    allow(ENV).to receive(:[]).with('ZAIM_CONSUMER_ID').and_return('test_consumer_id')
    allow(ENV).to receive(:[]).with('ZAIM_CONSUMER_SECRET').and_return('test_consumer_secret')
  end

  subject(:zaim_client) { ZaimApiClient.new }

  describe '#create_payment' do
    let(:payment_params) do
      {
        amount: 1000,
        date: '2025-10-14',
        genre_id: 19905,
        category_id: 199,
        merchant: 'Test Merchant'
      }
    end

    it 'makes a POST request to the Zaim payment API' do
      # Mock the OAuth access token and request
      access_token_obj = instance_double(OAuth::AccessToken)
      allow(OAuth::AccessToken).to receive(:new).and_return(access_token_obj)

      # Mock the response
      response = instance_double(Net::HTTPOK)
      allow(response).to receive(:code).and_return('200')
      allow(response).to receive(:body).and_return('{"money":{"id":123456}}')

      expected_params = {
        mapping: 1,
        amount: 1000,
        date: '2025-10-14',
        genre_id: 19905,
        category_id: 199,
        place: 'Test Merchant',
        name: 'Test Merchant'
        # NOTE: comment is not included when it's nil, based on the actual method implementation
      }

      expect(access_token_obj).to receive(:request).with(:post, 'https://api.zaim.net/v2/home/money/payment', expected_params).and_return(response)

      result = zaim_client.create_payment(payment_params)
      expect(result).to eq({ 'money' => { 'id' => 123456 } })
    end

    it 'includes optional parameters when provided' do
      # Mock the OAuth access token and request
      access_token_obj = instance_double(OAuth::AccessToken)
      allow(OAuth::AccessToken).to receive(:new).and_return(access_token_obj)

      # Mock the response
      response = instance_double(Net::HTTPOK)
      allow(response).to receive(:code).and_return('200')
      allow(response).to receive(:body).and_return('{"money":{"id":123456}}')

      payment_params_with_optional = payment_params.merge(
        comment: 'Test comment',
        from_account_id: 98765
      )

      expected_params = {
        mapping: 1,
        amount: 1000,
        date: '2025-10-14',
        genre_id: 19905,
        category_id: 199,
        place: 'Test Merchant',
        name: 'Test Merchant',
        comment: 'Test comment',
        from_account_id: 98765
      }

      expect(access_token_obj).to receive(:request).with(:post, 'https://api.zaim.net/v2/home/money/payment', expected_params).and_return(response)

      result = zaim_client.create_payment(payment_params_with_optional)
      expect(result).to eq({ 'money' => { 'id' => 123456 } })
    end
  end

  describe 'constants and configuration' do
    it 'has proper OAuth configuration' do
      # This test checks that the OAuth consumer can be initialized
      # without errors, given valid credentials
      expect { zaim_client }.not_to raise_error
    end
  end
end