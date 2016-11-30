require 'rspec'
require 'question'

describe Question do

  it 'inherits properly from ModelBase' do
    expect(Question.superclass).to be(ModelBase)
  end

end
