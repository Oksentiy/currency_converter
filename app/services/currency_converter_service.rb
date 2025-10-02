# frozen_string_literal: true

require "httparty"
require "bigdecimal"

class CurrencyConverterService
  class ApiError < StandardError; end

  # базовий URL можна перекривати через ENV (наприклад, для іншого провайдера)
  BASE_URL = ENV.fetch("CURRENCY_API_BASE", "https://api.frankfurter.dev/v1")
  CACHE_TTL = 1.hour

  def initialize(amount:, from:, to:)
    @amount = parse_amount(amount)
    @from   = normalize_currency(from)
    @to     = normalize_currency(to)
  end

  # Основний метод — викликай converter.call
  # Повертає: { amount:, from:, to:, rate:, converted: }
  def call
    validate!

    rate = fetch_rate(@from, @to)
    converted = (@amount * BigDecimal(rate.to_s)).round(2)

    {
      amount: @amount.to_f,
      from: @from,
      to: @to,
      rate: BigDecimal(rate.to_s).to_f,
      converted: converted.to_f
    }
  end

  private

  def parse_amount(value)
    BigDecimal(value.to_s)
  rescue ArgumentError, TypeError
    raise ApiError, "Невірна сума"
  end

  def normalize_currency(c)
    c.to_s.strip.upcase
  end

  def validate!
    raise ApiError, "Сума має бути більше 0" if @amount <= 0
    raise ApiError, "Валюти повинні бути різні" if @from == @to
  end

  # Отримує курс (із кешем)
  def fetch_rate(from, to)
    cache_key = "fx_rate:#{from}:#{to}"

    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      resp = HTTParty.get("#{BASE_URL}/latest", query: { from: from, to: to })

      unless resp.code == 200 && resp["rates"] && resp["rates"][to]
        raise ApiError, "Не вдалося отримати курс (status: #{resp.code})"
      end

      resp["rates"][to]
    end
  rescue SocketError, Errno::ECONNREFUSED => e
    raise ApiError, "Помилка мережі: #{e.message}"
  end
end
