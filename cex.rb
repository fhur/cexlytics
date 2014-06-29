require 'date'

file_path = ARGV[0]

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
    amount = csv_row[1].to_f
    currency = csv_row[2]
    balance = csv_row[3].to_f
    Transaction.new date, amount, currency, balance
  end
end

raw = File.read(file_path)
rows = raw.split("\r\n") # split the loaded string by new lines
rows.map! do |row|
  row.split "," # split each line by comma
end

# remove the first row because its a header
rows.delete_at 0

# filter only bitcoins actions
rows.select! do |row|
  row if row[2]=='BTC' or row[2]=='GHS'
end

# map the rows to transactions (Transaction)
transactions = rows.map do |row|
  Transaction.parse(row)
end

# reverse the order of transactions, latest should come first
transactions.reverse!

# separate ghs operations from btc operations
ghs_transactions = transactions.select do |transaction|
  transaction.is_ghs?
end

btc_transactions = transactions.select do |transaction|
  transaction.is_btc?
end

# calculate the daily earnings per GHash

# First, let's group transactions by day
# calculate todays date and iterate through every transaction, grouping them by day
date_map = {}
transactions.each do |transaction|
  date = transaction.date.to_date
  transactions_by_date = date_map[date]
  transactions_by_date = [] if transactions_by_date == nil
  transactions_by_date.push transaction
  date_map[date] = transactions_by_date
end

date_map.keys.sort.each do |date|
  txs = date_map[date]
  p txs.select { |tx| tx.is_btc? }.map { |tx| tx.amount}
end



