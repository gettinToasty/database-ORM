require_relative 'questions_database'

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
    return "replies" if self.is_a?(Reply)
    self.to_s.split(/(?<!^)(?=[A-Z])/).map(&:downcase).join("_") + "s"
  end

  def self.where(options)
    if options.is_a?(Hash)
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
    elsif options.is_a?(String)
      data = QuestionsDatabase.instance.execute(<<-SQL)
        SELECT
          *
        FROM
          #{self.tableize}
        WHERE
          #{options}
      SQL
    end
    data.map { |datum| self.new(datum) }
  end

  def self.method_missing(method_name, *args)
    if method_name =~ /find_by_(\w+)/
      call_where(method_name, *args)
    else
      super
    end
  end

  def self.respond_to_missing?(method_name, *args)
    method_name =~ /find_by_(\w+)/ || super
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

private
  def call_where(method_name, *args)
    keys = method_name =~ /(?:find_by_)(.+)/
    keys = keys[1].split('_and_')
    hash = {}
    keys.each { |key| hash[key] = args.shift }
    self.where(hash)
  end

end
