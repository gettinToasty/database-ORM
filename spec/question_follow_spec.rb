require 'rspec'
require 'question_follow'

describe QuestionFollow do
  subject(:follow) { QuestionFollow.new('id' => 1, 'user_id' => 2, 'question_id' => 3) }

  it 'inherits properly from ModelBase' do
    expect(QuestionFollow.superclass).to be(ModelBase)
  end
  
end
