require 'rspec'
require 'question_like'

describe QuestionLike do

  it 'inherits properly from ModelBase' do
    expect(QuestionLike.superclass).to be(ModelBase)
  end

end
