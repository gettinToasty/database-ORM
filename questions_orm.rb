require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class ModelBase

  def self.find_by_id(id)
    data = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.tableize}
      WHERE
        id = ?
    SQL
    self.new(data.first)
  end

  def self.all
    data = QuestionsDatabase.instance.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.tableize}
    SQL
  end

  def self.tableize
    self.to_s.split(/(?<!^)(?=[A-Z])/).map(&:downcase).join("_") + "s"
  end

  def self.where(options)
    cols = options.keys.map(&:to_s)
    vals = options.values
    data = QuestionsDatabase.instance.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.tableize}
      WHERE
        #{ array = []
          cols.each { |col| array << (col + ' = ' + '\'' + vals.shift.to_s + '\'') }
          array.join(' AND ')
        }
    SQL
    data.map { |datum| self.new(datum) }
  end

  def save
    vars = self.instance_variables.reverse
    vars_str = vars.map { |el| el.to_s([1..-1]) }
    if @id
      QuestionsDatabase.instance.execute(<<-SQL, *vars)
      UPDATE
        users
      SET
        #{
        str = ""
        vars_str[0...-1].each { |el| str += el + ' = ?' }
        str
        }
      WHERE
        id = ?
      SQL
    else
      QuestionsDatabase.instance.execute(<<-SQL, *vars)
      INSERT INTO
        #{self.tableize} (#{vals_str[0...-1].join(', ')})
      VALUES
        (#{
          arr = []
          vals_str[0...-1].length.times { arr << '?' }
          arr.join(', ')})
      SQL

      @id = QuestionsDatabase.instance.last_insert_row_id
    end
  end

  def self.method_missing(method_name, *args)
    keys = method_name.to_s.match(/(?:find_by_)(.+)/)
    keys = keys[1].split('_and_')
    hash = {}
    keys.each { |key| hash[key] = args.shift }
    self.where(hash)
  end

end

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

class QuestionFollow < ModelBase

  def self.followers_for_question_id(question_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        users.*
      FROM
        question_follows
      JOIN users
        ON users.id = question_follows.user_id
      WHERE
        question_follows.question_id = ?
    SQL
    data.map { |datum| User.new(datum) }
  end

  def self.followed_questions_for_user_id(user_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.*
      FROM
        question_follows
      JOIN questions
        ON questions.id = question_follows.question_id
      WHERE
        question_follows.user_id = ?
    SQL
    data.map { |datum| Question.new(datum) }
  end

  def self.most_followed_questions(n)
    data = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        questions.*
      FROM
        questions
      JOIN question_follows ON question_follows.question_id = questions.id
      GROUP BY
        question_follows.question_id
      ORDER BY
        COUNT(question_follows.user_id) DESC
      LIMIT ?

      SQL

    data.map { |datum| Question.new(datum) }
  end


  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
  end

end

class Reply < ModelBase

  attr_accessor :question_id, :parent_id, :body, :user_id

  def self.find_by_user_id(user_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    SELECT
      *
    FROM
      replies
    WHERE
      user_id = ?
    SQL
    data.map { |datum| Reply.new(datum) }
  end

  def self.find_by_question_id(question_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      *
    FROM
      replies
    WHERE
      question_id = ?
    SQL
    data.map { |datum| Reply.new(datum) }
  end

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
    @parent_id = options['parent_id']
    @body = options['body']
  end

  def author
    User.find_by_id(@user_id)
  end

  def question
    Question.find_by_id(@question_id)
  end

  def parent_reply
    Reply.find_by_id(@parent_id)
  end

  def child_replies
    data = QuestionsDatabase.instance.execute(<<-SQL, @id)
      SELECT
        *
      FROM
        replies
      WHERE
        parent_id = ?
    SQL
    data.map { |datum| Reply.new(datum) }
  end

end

class QuestionLike < ModelBase

  def self.likers_for_question_id(question_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        users.*
      FROM
        users
      JOIN question_likes ON users.id = question_likes.user_id
      WHERE
        question_id = ?
    SQL
    data.map { |datum| User.new(datum) }
  end

  def self.num_likes_for_question_id(question_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        COUNT(*) AS num_likes
      FROM
        question_likes
      WHERE
        question_id = ?
    SQL
    data.first['num_likes']
  end

  def self.liked_questions_for_user_id(user_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.*
      FROM
        questions
      JOIN question_likes ON questions.id = question_likes.question_id
      WHERE
        question_likes.user_id = ?
    SQL
    data.map { |datum| Question.new(datum) }
  end

  def self.most_liked_questions(n)
    data = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        questions.*
      FROM
        questions
      JOIN question_likes ON questions.id = question_likes.question_id
      GROUP BY
        question_likes.user_id
      ORDER BY
        COUNT(*) DESC
      LIMIT ?
    SQL
    data.map { |datum| Question.new(datum) }
  end

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
    @like_status = options['like_status']
  end

end
