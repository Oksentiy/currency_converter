require 'rails_helper'

RSpec.describe CurrencyConverterService do
  let(:amount) { 100 }
  let(:from) { 'USD' }
  let(:to) { 'EUR' }

  describe '#call' do
    subject { described_class.new(amount:, from:, to:) }

    context 'valid conversion' do
      it 'returns converted amount' do
        response_double = double(
          code: 200,
          :[] => { to => 0.9 }
        )
        allow(HTTParty).to receive(:get).and_return(response_double)

        result = subject.call
        expect(result[:amount]).to eq(amount.to_f)
        expect(result[:from]).to eq(from)
        expect(result[:to]).to eq(to)
        expect(result[:converted]).to eq((amount * 0.9).round(2))
      end
    end

    context 'invalid amount' do
      let(:amount) { -5 }
      it 'raises ApiError' do
        expect { subject.call }.to raise_error(CurrencyConverterService::ApiError, /Amount must be greater than 0/)
      end
    end

    context 'same currency' do
      let(:to) { 'USD' }
      it 'raises ApiError' do
        expect { subject.call }.to raise_error(CurrencyConverterService::ApiError, /Currencies must be different/)
      end
    end
  end
end
