require 'rails_helper'

RSpec.describe AppleReceiptService do
  let(:verify_url) { 'http://example.com/receipt-verify' }
  before { stub_const('AppleReceiptService::VERIFICATION_URL', verify_url) }
  subject { described_class.new('fake_receipt') }

  def stub_receipt_verification(latest_receipt_info: {}, status: 0)
    response = { status: status, latest_receipt_info: latest_receipt_info }.to_json
    stub_request(:post, verify_url).to_return(
      status: 200,
      body: response,
      headers: {
        'Content-Type' => 'application/json',
        'Content-Length' => response.length
      }
    )
  end

  it 'should raise an exception if the verification response status is nonzero' do
    stub_receipt_verification(status: 21100) # rubocop:disable Style/NumericLiterals
    expect { subject }.to raise_exception(AppleReceiptService::Error)
  end

  context 'with a valid receipt' do
    describe '#start_date' do
      it 'should return the purchase_date field from the receipt as a Time object' do
        stub_receipt_verification(latest_receipt_info: {
          purchase_date: '2012-04-30T15:05:55.000+00:00'
        })
        expect(subject.start_date).to be_a(Time)
        expect(subject.start_date).to eq(Time.new(2012, 4, 30, 15, 5, 55, 0))
      end
    end

    describe '#end_date' do
      it 'should return the expires_date field from the receipt as a Time object' do
        stub_receipt_verification(latest_receipt_info: {
          expires_date: '2012-04-30T15:05:55.000+00:00'
        })
        expect(subject.end_date).to be_a(Time)
        expect(subject.end_date).to eq(Time.new(2012, 4, 30, 15, 5, 55, 0))
      end
    end

    describe '#billing_id' do
      it 'should return the original_transaction_id' do
        stub_receipt_verification(latest_receipt_info: {
          original_transaction_id: '_TEST_'
        })
        expect(subject.billing_id).to eq('_TEST_')
      end
    end
  end
end
