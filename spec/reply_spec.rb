require 'rspec'
require 'reply'

describe Reply do

  it 'inherits properly from ModelBase' do
    expect(Reply.superclass).to be(ModelBase)
  end

end
