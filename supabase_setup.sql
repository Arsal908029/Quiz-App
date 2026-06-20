-- SUPABASE QUIZ MASTER SETUP SCRIPT
-- Copy and paste this script into the Supabase SQL Editor (https://supabase.com dashboard -> Project -> SQL Editor -> New Query)
-- Run this script to create all tables, set up security policies, and seed sample quiz categories and questions.

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Drop existing tables if they exist to start fresh
drop table if exists public.daily_challenges cascade;
drop table if exists public.user_progress cascade;
drop table if exists public.quiz_sessions cascade;
drop table if exists public.questions cascade;
drop table if exists public.categories cascade;
drop table if exists public.users cascade;

-- 1. Create Categories Table
create table public.categories (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  description text,
  icon text,
  color text,
  question_count integer default 0,
  created_at timestamptz default now()
);

-- 2. Create Questions Table
create table public.questions (
  id uuid default gen_random_uuid() primary key,
  category_id uuid references public.categories(id) on delete cascade,
  question text not null,
  options jsonb not null,
  correct_answer text not null,
  explanation text,
  difficulty text default 'medium',
  points integer default 10,
  created_at timestamptz default now()
);

-- 3. Create Public Users Profiles Table (linked to Supabase Auth.users)
create table public.users (
  id uuid references auth.users(id) on delete cascade primary key,
  email text,
  name text,
  avatar_url text,
  matric_number text,
  faculty text,
  department text,
  university text,
  total_score integer default 0,
  total_quizzes integer default 0,
  created_at timestamptz default now()
);

-- 4. Create Quiz Sessions Table
create table public.quiz_sessions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users(id) on delete cascade,
  category_id uuid references public.categories(id) on delete cascade,
  score integer default 0,
  total_questions integer default 0,
  completed_at timestamptz default now()
);

-- 5. Create User Progress Table
create table public.user_progress (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users(id) on delete cascade,
  category_id uuid references public.categories(id) on delete cascade,
  highest_score integer default 0,
  attempts integer default 1,
  last_played timestamptz default now(),
  constraint unique_user_category unique(user_id, category_id)
);

-- 6. Create Daily Challenges Table
create table public.daily_challenges (
  id uuid default gen_random_uuid() primary key,
  category_id uuid references public.categories(id) on delete cascade,
  date date default current_date unique,
  created_at timestamptz default now()
);

-- 7. Enable Row Level Security (RLS)
alter table public.categories enable row level security;
alter table public.questions enable row level security;
alter table public.users enable row level security;
alter table public.quiz_sessions enable row level security;
alter table public.user_progress enable row level security;
alter table public.daily_challenges enable row level security;

-- 8. Create Access Policies
create policy "Allow public read access to categories" on public.categories for select using (true);
create policy "Allow public read access to questions" on public.questions for select using (true);
create policy "Allow public read access to users" on public.users for select using (true);
create policy "Allow authenticated users to insert their own profile" on public.users for insert with check (auth.uid() = id);
create policy "Allow users to update their own profile" on public.users for update using (auth.uid() = id);
create policy "Allow users to read their own quiz sessions" on public.quiz_sessions for select using (auth.uid() = user_id);
create policy "Allow users to insert their own quiz sessions" on public.quiz_sessions for insert with check (auth.uid() = user_id);
create policy "Allow users to read their own progress" on public.user_progress for select using (auth.uid() = user_id);
create policy "Allow users to insert/update their own progress" on public.user_progress for insert with check (auth.uid() = user_id);
create policy "Allow users to update their own progress" on public.user_progress for update using (auth.uid() = user_id);
create policy "Allow public read access to daily challenges" on public.daily_challenges for select using (true);

-- 9. Seed Sample Categories
insert into public.categories (name, description, icon, color, question_count) values
('Science', 'Test your science knowledge', '🔬', '#4CAF50', 5),
('History', 'Historical facts and events', '📜', '#FF9800', 5),
('Geography', 'World geography questions', '🌍', '#2196F3', 5),
('Mathematics', 'Math problems and concepts', '🧮', '#9C27B0', 5),
('Technology', 'Computers, programming, and tech history', '💻', '#607D8B', 5),
('Sports', 'Athletes, rules, and sporting events', '⚽', '#E91E63', 5),
('Entertainment', 'Movies, music, pop culture, and books', '🎬', '#FF5722', 5),
('General Knowledge', 'A mix of trivia across diverse subjects', '🧠', '#00BCD4', 5);

-- 10. Seed Questions (5 per category)
insert into public.questions (category_id, question, options, correct_answer, explanation, difficulty, points) values
-- Science Questions
((select id from public.categories where name = 'Science' limit 1), 'What is the chemical symbol for water?', '["H2O", "O2", "CO2", "H2"]'::jsonb, 'H2O', 'Water is made of two hydrogen atoms and one oxygen atom.', 'easy', 10),
((select id from public.categories where name = 'Science' limit 1), 'Which planet is known as the Red Planet?', '["Earth", "Mars", "Jupiter", "Saturn"]'::jsonb, 'Mars', 'Mars appears red due to iron oxide (rust) on its surface.', 'easy', 10),
((select id from public.categories where name = 'Science' limit 1), 'What gas do plants absorb from the atmosphere for photosynthesis?', '["Oxygen", "Carbon Dioxide", "Nitrogen", "Hydrogen"]'::jsonb, 'Carbon Dioxide', 'Plants absorb carbon dioxide (CO2) and release oxygen (O2) during photosynthesis.', 'medium', 15),
((select id from public.categories where name = 'Science' limit 1), 'What is the powerhouse of the cell?', '["Nucleus", "Ribosome", "Mitochondria", "Golgi Apparatus"]'::jsonb, 'Mitochondria', 'Mitochondria generate most of the chemical energy needed to power the cell''s biochemical reactions.', 'medium', 15),
((select id from public.categories where name = 'Science' limit 1), 'What is the speed of light in a vacuum (approximately)?', '["150,000 km/s", "300,000 km/s", "450,000 km/s", "600,000 km/s"]'::jsonb, '300,000 km/s', 'The speed of light in vacuum is exactly 299,792,458 meters per second, or about 300,000 km/s.', 'hard', 20),

-- History Questions
((select id from public.categories where name = 'History' limit 1), 'In which year did World War II end?', '["1918", "1939", "1945", "1950"]'::jsonb, '1945', 'World War II ended in September 1945 with the formal surrender of Japan.', 'easy', 10),
((select id from public.categories where name = 'History' limit 1), 'Who was the first President of the United States?', '["Abraham Lincoln", "Thomas Jefferson", "George Washington", "John Adams"]'::jsonb, 'George Washington', 'George Washington served as president from 1789 to 1797.', 'easy', 10),
((select id from public.categories where name = 'History' limit 1), 'Who painted the Mona Lisa?', '["Michelangelo", "Raphael", "Vincent van Gogh", "Leonardo da Vinci"]'::jsonb, 'Leonardo da Vinci', 'Leonardo da Vinci painted the Mona Lisa in Florence between 1503 and 1519.', 'medium', 15),
((select id from public.categories where name = 'History' limit 1), 'Which empire built the Colosseum in Rome?', '["Greek Empire", "Roman Empire", "Persian Empire", "Egyptian Empire"]'::jsonb, 'Roman Empire', 'The Colosseum was built by the Roman Empire starting under Emperor Vespasian in 72 AD.', 'medium', 15),
((select id from public.categories where name = 'History' limit 1), 'Who was the first human to journey into outer space?', '["Neil Armstrong", "Yuri Gagarin", "Buzz Aldrin", "John Glenn"]'::jsonb, 'Yuri Gagarin', 'Soviet cosmonaut Yuri Gagarin completed a single orbit of Earth on April 12, 1961.', 'hard', 20),

-- Geography Questions
((select id from public.categories where name = 'Geography' limit 1), 'What is the capital of France?', '["London", "Berlin", "Paris", "Rome"]'::jsonb, 'Paris', 'Paris has been the capital of France since the late 10th century.', 'easy', 10),
((select id from public.categories where name = 'Geography' limit 1), 'Which is the largest ocean on Earth?', '["Atlantic Ocean", "Indian Ocean", "Arctic Ocean", "Pacific Ocean"]'::jsonb, 'Pacific Ocean', 'The Pacific Ocean is the largest and deepest of Earth''s oceanic divisions.', 'easy', 10),
((select id from public.categories where name = 'Geography' limit 1), 'Which is the longest river in the world?', '["Amazon River", "Nile River", "Yangtze River", "Mississippi River"]'::jsonb, 'Nile River', 'The Nile River is traditionally considered the longest in the world, stretching over 6,650 kilometers.', 'medium', 15),
((select id from public.categories where name = 'Geography' limit 1), 'What is the smallest country in the world?', '["Monaco", "San Marino", "Vatican City", "Liechtenstein"]'::jsonb, 'Vatican City', 'Vatican City is the smallest independent state in the world, both by area and population.', 'medium', 15),
((select id from public.categories where name = 'Geography' limit 1), 'Which desert is the largest hot desert in the world?', '["Gobi Desert", "Kalahari Desert", "Sahara Desert", "Arabian Desert"]'::jsonb, 'Sahara Desert', 'The Sahara is the largest hot desert, though the Antarctic and Arctic deserts are larger cold deserts.', 'hard', 20),

-- Mathematics Questions
((select id from public.categories where name = 'Mathematics' limit 1), 'What is the square root of 144?', '["10", "11", "12", "14"]'::jsonb, '12', '12 multiplied by 12 equals 144.', 'easy', 10),
((select id from public.categories where name = 'Mathematics' limit 1), 'Solve: 5 * (10 - 3) + 2', '["37", "35", "27", "17"]'::jsonb, '37', 'Follow BODMAS/PEMDAS: 10 - 3 = 7. Then 5 * 7 = 35. Finally 35 + 2 = 37.', 'easy', 10),
((select id from public.categories where name = 'Mathematics' limit 1), 'What is the value of Pi (to two decimal places)?', '["3.12", "3.14", "3.16", "3.18"]'::jsonb, '3.14', 'Pi is approximately 3.14159, which rounds to 3.14.', 'medium', 15),
((select id from public.categories where name = 'Mathematics' limit 1), 'What is 15% of 200?', '["15", "20", "30", "45"]'::jsonb, '30', '15/100 * 200 = 15 * 2 = 30.', 'medium', 15),
((select id from public.categories where name = 'Mathematics' limit 1), 'If a triangle has sides of 3cm and 4cm, and a right angle between them, what is the length of the hypotenuse?', '["5cm", "6cm", "7cm", "8cm"]'::jsonb, '5cm', 'Using Pythagoras: 3^2 + 4^2 = 9 + 16 = 25. Square root of 25 is 5.', 'hard', 20),

-- Technology Questions
((select id from public.categories where name = 'Technology' limit 1), 'What does CPU stand for?', '["Central Processing Unit", "Computer Processing Utility", "Core Process Unit", "Control Power Unit"]'::jsonb, 'Central Processing Unit', 'CPU stands for Central Processing Unit, the main processor that executes instructions in a computer.', 'easy', 10),
((select id from public.categories where name = 'Technology' limit 1), 'Which programming language is primarily used for the behavior of web pages?', '["Python", "C++", "Java", "JavaScript"]'::jsonb, 'JavaScript', 'JavaScript is the core language used to make web pages interactive and dynamic on the client side.', 'easy', 10),
((select id from public.categories where name = 'Technology' limit 1), 'Who is known as the co-founder of Microsoft alongside Paul Allen?', '["Steve Jobs", "Bill Gates", "Mark Zuckerberg", "Larry Page"]'::jsonb, 'Bill Gates', 'Bill Gates co-founded Microsoft in 1975, which became the world''s largest personal computer software company.', 'medium', 15),
((select id from public.categories where name = 'Technology' limit 1), 'What is the main standard language used to manage relational databases?', '["HTML", "SQL", "JSON", "XML"]'::jsonb, 'SQL', 'SQL (Structured Query Language) is the standard language used to interact with relational database management systems.', 'medium', 15),
((select id from public.categories where name = 'Technology' limit 1), 'What does HTML stand for?', '["HyperText Markup Language", "HighTransfer Machine Language", "Hyperlink Text Manage Line", "Home Tool Markup Language"]'::jsonb, 'HyperText Markup Language', 'HTML stands for HyperText Markup Language, the standard formatting language used for creating web pages.', 'hard', 20),

-- Sports Questions
((select id from public.categories where name = 'Sports' limit 1), 'How many players are on the field for each team in a standard soccer match?', '["9", "10", "11", "12"]'::jsonb, '11', 'A standard soccer match is played between two teams of 11 players each, including one goalkeeper.', 'easy', 10),
((select id from public.categories where name = 'Sports' limit 1), 'Which national team won the FIFA World Cup in Qatar in 2022?', '["France", "Brazil", "Germany", "Argentina"]'::jsonb, 'Argentina', 'Argentina won the 2022 FIFA World Cup, defeating France in a penalty shootout after a 3-3 draw.', 'easy', 10),
((select id from public.categories where name = 'Sports' limit 1), 'What is the approximate length of a standard marathon in miles?', '["26.2", "20.5", "30.0", "15.4"]'::jsonb, '26.2', 'A marathon is a long-distance foot race with an official distance of 42.195 kilometers, or 26 miles 385 yards (26.2 miles).', 'medium', 15),
((select id from public.categories where name = 'Sports' limit 1), 'In which sport do players perform slam dunks?', '["Tennis", "Volleyball", "Basketball", "Baseball"]'::jsonb, 'Basketball', 'A slam dunk is a type of basketball shot performed when a player jumps in the air and forces the ball through the basket with one or both hands.', 'medium', 15),
((select id from public.categories where name = 'Sports' limit 1), 'How many rings are on the Olympic flag?', '["4", "5", "6", "7"]'::jsonb, '5', 'The Olympic flag consists of five interlaced rings (blue, yellow, black, green, and red) representing the five inhabited continents.', 'hard', 20),

-- Entertainment Questions
((select id from public.categories where name = 'Entertainment' limit 1), 'Which actor portrayed Tony Stark / Iron Man in the Marvel Cinematic Universe?', '["Chris Evans", "Robert Downey Jr.", "Chris Hemsworth", "Mark Ruffalo"]'::jsonb, 'Robert Downey Jr.', 'Robert Downey Jr. played Iron Man starting in 2008, launching the highly successful MCU franchise.', 'easy', 10),
((select id from public.categories where name = 'Entertainment' limit 1), 'Which South Korean film made history by winning the Best Picture Oscar in 2020?', '["Oldboy", "Parasite", "The Handmaiden", "Minari"]'::jsonb, 'Parasite', 'Directed by Bong Joon-ho, Parasite was the first non-English-language film to win the Academy Award for Best Picture.', 'easy', 10),
((select id from public.categories where name = 'Entertainment' limit 1), 'Who was the iconic lead singer of the rock band Queen?', '["David Bowie", "Mick Jagger", "Freddie Mercury", "Elton John"]'::jsonb, 'Freddie Mercury', 'Freddie Mercury was the charismatic lead vocalist and songwriter of the legendary British rock band Queen.', 'medium', 15),
((select id from public.categories where name = 'Entertainment' limit 1), 'In Harry Potter, what is the name of Harry''s pet owl?', '["Scabbers", "Crookshanks", "Fang", "Hedwig"]'::jsonb, 'Hedwig', 'Hedwig was Harry''s snowy owl, given to him as an 11th birthday present by Rubeus Hagrid.', 'medium', 15),
((select id from public.categories where name = 'Entertainment' limit 1), 'What is the highest-grossing movie of all time (unadjusted for inflation)?', '["Avengers: Endgame", "Titanic", "Avatar", "Star Wars: The Force Awakens"]'::jsonb, 'Avatar', 'James Cameron''s Avatar, released in 2009, is the highest-grossing film of all time, earning over $2.9 billion.', 'hard', 20),

-- General Knowledge Questions
((select id from public.categories where name = 'General Knowledge' limit 1), 'What is the largest country in the world by land area?', '["Canada", "USA", "China", "Russia"]'::jsonb, 'Russia', 'Russia is the largest country, covering over 17 million square kilometers (about 11% of Earth''s total land area).', 'easy', 10),
((select id from public.categories where name = 'General Knowledge' limit 1), 'Which mammal is known as the King of the Jungle?', '["Tiger", "Lion", "Elephant", "Leopard"]'::jsonb, 'Lion', 'The lion is traditionally referred to as the "King of the Jungle", though they primarily live in grasslands and savannas.', 'easy', 10),
((select id from public.categories where name = 'General Knowledge' limit 1), 'How many teeth does a typical adult human have?', '["28", "30", "32", "34"]'::jsonb, '32', 'A typical adult human has 32 permanent teeth, including wisdom teeth.', 'medium', 15),
((select id from public.categories where name = 'General Knowledge' limit 1), 'What is the currency of Japan?', '["Won", "Yen", "Yuan", "Ringgit"]'::jsonb, 'Yen', 'The Japanese Yen is the official currency of Japan and the third most traded currency in the foreign exchange market.', 'medium', 15),
((select id from public.categories where name = 'General Knowledge' limit 1), 'Which element on the periodic table has the atomic number 1?', '["Helium", "Oxygen", "Hydrogen", "Carbon"]'::jsonb, 'Hydrogen', 'Hydrogen is the lightest chemical element and has the atomic number 1, consisting of a single proton and electron.', 'hard', 20);

-- 11. Create a daily challenge for today
insert into public.daily_challenges (category_id, date)
select id, current_date
from public.categories
where name = 'Science'
limit 1;
