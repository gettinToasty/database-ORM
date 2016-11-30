require_relative 'model_base'
require_relative 'user'
require_relative 'question_follow'
require_relative 'reply'
require_relative 'question_like'

class Question < ModelBase

  attr_accessor :user_id, :title, :body

  def self.find_by_author_id(user_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    SELECT
      *
    FROM
      questions
    WHERE
      user_id = ?
    SQL
    data.map { |datum| Question.new(datum) }
  end

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end

  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @title = options['title']
    @body = options['body']
  end

  def followers
    QuestionFollow.followers_for_question_id(@id)
  end

  def author
    User.find_by_id(@user_id)
  end

  def replies
    Reply.find_by_question_id(@id)
  end

  def likers
    QuestionLike.likers_for_question_id(@id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(@id)
  end

end
