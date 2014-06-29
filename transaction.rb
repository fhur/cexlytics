require 'date'
require 'bigdecimal'

class Transaction

  attr_reader :date
  attr_reader :amount
  attr_reader :currency
  attr_reader :balance

  def initialize(date, amount, currency, balance)
    @date = date
    @amount = amount
    @currency = currency
    @balance = balance
  end

  # returns true if this transaction is for gigahashes
  def is_ghs?
    currency == 'GHS'
  end

  #returns true if this transaction is for bitcoins
  def is_btc?
    currency == 'BTC'
  end

  # given a csv row array, it returns a parsed Transaction object
  def Transaction.parse(csv_row)
    date = DateTime.parse csv_row[0]
    amount = BigDecimal.new csv_row[1]
    currency = csv_row[2]
    balance = BigDecimal.new csv_row[3]
    Transaction.new date, amount, currency, balance
  end
end

