require 'rspec'
require 'user'

describe User do

  it 'inherits properly from ModelBase' do
    expect(User.superclass).to be(ModelBase)
  end

end
