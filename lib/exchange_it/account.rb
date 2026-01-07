# frozen_string_literal: true

module ExchangeIt
  class Account
    include ExchangeIt::Utils::Uid

    attr_reader :uid, :balance

    def initialize(user)
      @uid = hash user.name, user.surname
      @balance = 0
    end

    def transfer(reciever, amount)
      withdraw amount
      reciever.deposit amount
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
