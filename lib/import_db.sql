CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname VARCHAR(140) NOT NULL,
  lname VARCHAR(140) NOT NULL
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  user_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_follows (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  parent_id INTEGER,
  user_id INTEGER NOT NULL,
  body TEXT NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (parent_id) REFERENCES replies(id)
);

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  like_status BOOLEAN,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO
  users (fname, lname)
VALUES
  ('Sean', 'Beyer'),
  ('Nick', 'Vizzutti');

INSERT INTO
  questions (title, body, user_id)
VALUES
  ('How to install Ruby?', 'How do I install Ruby on OSX?', (SELECT id FROM users
  WHERE fname = 'Sean' AND lname = 'Beyer')),
  ('Why is my sqlite3 gem not installing?', 'I cannot install this gem on Linux!', (SELECT id FROM
  users WHERE fname = 'Nick' AND lname = 'Vizzutti'));

INSERT INTO
  question_follows (question_id, user_id)
VALUES
  (1, 1),
  (1, 2),
  (2, 2);

INSERT INTO
  replies (question_id, parent_id, user_id, body)
VALUES
  (1, NULL, 2, 'Open termiinal and write command ''apt-get ruby 2.1.0'' '),
  (1, 1, 1, 'That''s the Linux command, not OSX. ');


  INSERT INTO
    question_likes (user_id, like_status, question_id)
  VALUES
    (1, 'TRUE', 2); 
