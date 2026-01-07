# frozen_string_literal: true

RSpec.describe ExchangeIt::User do
  let(:user) { described_class.new 'John', 'Doe' }
  let(:user_no_data) { described_class.new nil, nil }

  it 'returns name' do
    expect(user.name).to eq('John')
    expect(user.name).to be_an_instance_of(String)
  end

  it 'returns name as a string' do
    expect(user_no_data.name).to be_an_instance_of(String)
  end

  it 'returns surname' do
    expect(user.name).to eq('John')
  end

  it 'returns surname as a string' do
    expect(user_no_data.surname).to be_an_instance_of(String)
  end
end
