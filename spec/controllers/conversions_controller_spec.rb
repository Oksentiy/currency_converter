# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConversionsController, type: :controller do
  describe 'GET #index' do
    let(:amount) { 100 }
    let(:from) { 'USD' }
    let(:to) { 'EUR' }

    it 'assigns currencies' do
      get :index
      expect(assigns(:currencies)).to eq(%w[USD EUR GBP PLN CAD AUD])
    end

    it 'calls CurrencyConverterService with valid params and assigns result' do
      service_double = double(call: { converted: 90, amount: amount.to_f, from:, to:, rate: 0.9 })
      allow(CurrencyConverterService).to receive(:new).and_return(service_double)

      get :index, params: { amount:, from:, to: }

      expect(assigns(:result)[:converted]).to eq(90)
      expect(CurrencyConverterService).to have_received(:new).with(amount:, from:, to:)
    end

    it 'handles ApiError and sets flash alert' do
      allow_any_instance_of(CurrencyConverterService).to receive(:call).and_raise(CurrencyConverterService::ApiError, 'API failed')

      get :index, params: { amount:, from:, to: }

      expect(flash.now[:alert]).to eq('API failed')
    end

    it 'does not call service if params are missing' do
      get :index
      expect(assigns(:result)).to be_nil
    end
  end
end
