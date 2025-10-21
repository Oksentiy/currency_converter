# frozen_string_literal: true

require "httparty"
require "bigdecimal"

class CurrencyConverterService
  class ApiError < StandardError; end

  BASE_URL = ENV.fetch("CURRENCY_API_BASE", "https://api.frankfurter.dev/v1")
  CACHE_TTL = 1.hour

  def initialize(amount:, from:, to:)
    @amount = parse_amount(amount)
    @from   = normalize_currency(from)
    @to     = normalize_currency(to)
  end

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
    raise ApiError, "Invalid amount"
  end

  def normalize_currency(c)
    c.to_s.strip.upcase
  end

  def validate!
    raise ApiError, "Amount must be greater than 0" if @amount <= 0
    raise ApiError, "Currencies must be different" if @from == @to
  end

  # Fetches the exchange rate (with caching)
  def fetch_rate(from, to)
    cache_key = "fx_rate:#{from}:#{to}"

    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      resp = HTTParty.get("#{BASE_URL}/latest", query: { from: from, to: to })

      unless resp.code == 200 && resp["rates"] && resp["rates"][to]
        raise ApiError, "Failed to fetch rate (status: #{resp.code})"
      end

      resp["rates"][to]
    end
  rescue SocketError, Errno::ECONNREFUSED => e
    raise ApiError, "Network error: #{e.message}"
  end
end
