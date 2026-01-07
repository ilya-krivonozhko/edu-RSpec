# frozen_string_literal: true

module ExchangeIt
  class User
    attr_reader :name, :surname

    def initialize(name, surname)
      @name = name.is_a?(String) ? name : name.to_s
      @surname = surname.is_a?(String) ? surname : surname.to_s
    end
  end
end
