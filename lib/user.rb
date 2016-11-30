require_relative 'model_base'
require_relative 'question'
require_relative 'question_follow'
require_relative 'reply'
require_relative 'question_like'

class User < ModelBase

  attr_accessor :fname, :lname

  def self.find_by_name(name)
    data = QuestionsDatabase.instance.execute(<<-SQL, name)
      SELECT
        *
      FROM
        users
      WHERE
        name = ?
    SQL
    data.map { |datum| User.new(datum) }
  end

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def authored_questions
    Question.find_by_author_id(@id)
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end

  def followed_questions
    QuestionFollow.followed_questions_for_user_id(@id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(@id)
  end

  def average_karma
    data = QuestionsDatabase.instance.execute(<<-SQL, @id)
      SELECT
        (COUNT(question_likes.like_status) /
          CAST(COUNT(users_questions.id) AS FLOAT)) AS avg_karma
      FROM
        (SELECT
          DISTINCT *
        FROM
          questions
        WHERE
          questions.user_id = ?) AS users_questions
      LEFT OUTER JOIN question_likes
        ON question_likes.question_id = users_questions.id
      GROUP BY
        question_likes.question_id
    SQL
    data.first["avg_karma"]
  end

end
