require 'sqlite3'
require 'rspec'
require 'questions_database'

describe QuestionsDatabase do

  it 'is a singleton class' do
    expect { QuestionsDatabase.new }.to raise_error(/private method/)
  end

  describe '#initialize' do
    subject(:db) { QuestionsDatabase.instance}

    it 'translates the type of database output' do
      expect(db.type_translation).to be true
    end

    it 'gives the query results as a hash' do
      expect(db.results_as_hash).to be true
    end

  end

end
