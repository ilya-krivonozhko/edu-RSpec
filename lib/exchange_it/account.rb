# frozen_string_literal: true

module ExchangeIt
  class Account
    include ExchangeIt::Utils::Uid
    include ExchangeIt::Api::Converter

    attr_reader :uid, :balance

    def initialize(user)
      @uid = hash user.name, user.surname
      @balance = 0
    end

    def transfer(reciever, amount)
      withdraw amount
      reciever.deposit amount
    end

    def transfer_with_conversion(reciever, amount, in_currency, out_currency)
      converted_amount = convert sum: amount, from: in_currency, to: out_currency

      withdraw amount
      reciever.deposit converted_amount
    end

    def withdraw(amount)
      raise(ExchangeIt::IncorectSum, 'Amount must be positive!') unless amount.positive?
      raise(ExchangeIt::NotEnoughFunds, "Available: #{@balance} but tried to withdraw #{amount}") if amount > @balance

      @balance -= amount
    end

    def deposit(amount)
      raise(ExchangeIt::IncorectSum, 'Amount must be positive!') unless amount.positive?

      @balance += amount
    end
  end
end
