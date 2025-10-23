# frozen_string_literal: true

class ConversionsController < ApplicationController
  CURRENCIES = %w[USD EUR GBP PLN CAD AUD].freeze

  def index
    @currencies = CURRENCIES

    return unless params[:amount].present? && params[:from].present? && params[:to].present?

    converter = CurrencyConverterService.new(
      amount: params[:amount].to_f,
      from:   params[:from],
      to:     params[:to]
    )

    begin
      @result = converter.call
    rescue CurrencyConverterService::ApiError => e
      flash.now[:alert] = e.message
    end
  end
end
