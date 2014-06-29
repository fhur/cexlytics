# Under construction!!!
#
# Given 2 files as input, your BTC transaction mining history and your GHS transaction trade history
# This script outps a csv to stdout with your daily GHash balance and your daily BTC minings
#

# Part 1, parse input
#
require './transaction.rb'

# returns a list of transactions given a file_name with a csv
def get_transactions(file_name)
  raw_mining_file = File.read file_name
  rows = raw_mining_file.split "\r\n"
  rows.map! do |row|
    row.split ","
  end

  rows.delete_at 0 # delete the first row, because its a header

  # map to a list of transactions
  transactions = rows.map do |row|
    Transaction.parse(row)
  end

  return transactions.sort { |a,b| a.date <=> b.date }
end

mining_transactions =  get_transactions 'transactions-mining-BTC.csv'
ghs_transactions = get_transactions 'transactions-trade-GHS.csv'

# Part 2
# Transactions are now loaded into mining_transactions and ghs_transactions, now lets obtain the date range

mining_dates = mining_transactions.map do |tx|
  tx.date
end

min_date = mining_dates.min.to_date
max_date = mining_dates.max.to_date

# Part 3
# given the date range and the current GHS balance, we will now attempt to calculate the GHS balance for
# each date in [min_date, max_date]
#

ghs_balance = [] # initialize empty ghs_balance

puts "You have been mining for #{(max_date-min_date).to_i} days"

# given a list of transactions ordered by date
# an index and a date
# returns all transactions that ocurred on that day
def find_transactions_on_date(transactions, index, date)
  result = []
  index.upto(transactions.size-1) do |i|
    tx = transactions[i]
    result.push tx if tx.date.to_date == date
  end
  return result
end

# given a list of transactions that happened on the same day, calculate
# the weighted average balance.
# The weight is calculated with the number of minutes that balance held
# this list is also ordered by date
def calc_weighted_average_balance(txs)
  total_minutes = 60*24
  minutes = 0
  result = 0
  txs.each do |tx|
    date = tx.date
    minute = date.minute + date.hour*60
    weight = minute - minutes
    result += tx.balance*weight
  end
  return result/total_minutes
end

# a couple of notes on the data
# 1. There can be more than 1 GHS transaction for any given day
#    the GHS balance for that day is then the average of the GHS
#    This balance is calculated as the weighted average

# Given a list of transactions ordered by date,
# calculates the balance for a given day and returns it as a map
# maps Date => balance for that day
def calc_balance_map(txs)
  balance_map = {}
  last_date = nil
  txs.each_with_index do |tx, i|
    date = tx.date.to_date
    next if last_date == date
    transactions_on_day = find_transactions_on_date(txs, i, date)
    balance_map[date] = calc_weighted_average_balance(transactions_on_day)
    balance_map[date.next_day] = transactions_on_day.last.balance
    last_date = date
  end
  return balance_map
end

# now given that some days are empty, we need to 'fill them up'
def fill_missing_dates(date_init, date_end, balance_map)
  date_init.upto(date_end) do |date|
    if not balance_map.include? date
      balance_map[date] = balance_map[date.prev_day]
    end
  end
  return balance_map
end

#
def calc_mining_map(mining_transactions)
  map = {}
  last_date = nil
  mining_transactions.each_with_index do |tx,i|
    date = tx.date.to_date
    next if last_date == date
    txs = find_transactions_on_date(mining_transactions, i, date)
    sum_amount = txs.map { |t| t.amount }.reduce(:+)
    map[date] = sum_amount
    last_date = date
  end
  return map
end

ghs_date_map = fill_missing_dates(min_date, max_date, calc_balance_map(ghs_transactions))
mining_date_map = fill_missing_dates(min_date, max_date, calc_mining_map(mining_transactions))

ghs_date_map.sort.each do |row|
  date = row[0]
  ghs_balance = row[1]
  mining_balance = mining_date_map[date]
  puts "#{date},#{ghs_balance.to_f},#{mining_balance.to_f}"
end

