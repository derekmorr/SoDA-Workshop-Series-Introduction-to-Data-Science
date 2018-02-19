-- exercise 1, loading data

CREATE TABLE legislation(
  id SERIAL PRIMARY KEY,
  session INT NOT NULL,
  chamber TEXT NOT NULL CHECK (chamber IN ('HR', 'S')),
  bill_number INT NOT NULL,
  bill_type TEXT NOT NULL CHECK (bill_type IN ( 'IH', 'IS')),
  section INT NOT NULL CHECK (section > 0),
  cosponsors INT NOT NULL CHECK (cosponsors >= 0),
  intro_date DATE NOT NULL,
  title TEXT NOT NULL,
  fullname TEXT NOT NULL,
  major_topic TEXT NOT NULL,
  party TEXT NOT NULL
);

-- from a unix shell:
-- for i in `ls /home/derek/soda-dvm/Workshop_Data/Multi_Datasets/dataset_*.csv`; do echo "processing $i";  psql -c "COPY legislation (session, chamber, bill_number, bill_type, section, cosponsors, intro_date, title, fullname, major_topic, party) FROM '$i' WITH CSV HEADER"; done


-- exercise 2

-- create a unique bill_id
ALTER TABLE legislation ADD COLUMN bill_id TEXT;
UPDATE legislation SET bill_id = session || '-' || chamber || '-' || bill_number; 
ALTER TABLE legislation ALTER COLUMN bill_id SET NOT NULL;

-- add total section count to legislation data
ALTER TABLE legislation ADD COLUMN sections INT;
CREATE TEMPORARY TABLE section_counts AS SELECT bill_id, count(bill_id) as section_count FROM legislation GROUP BY bill_id;
CREATE INDEX ON section_counts(bill_id);
CREATE INDEX ON legislation(bill_id);
UPDATE legislation SET sections = (SELECT section_count FROM section_counts WHERE section_counts.bill_id = legislation.bill_id);
ALTER TABLE legislation ALTER COLUMN sections SET NOT NULL;
DROP TABLE section_counts;

-- remove duplicate rows for each bill_id
CREATE TEMPORARY TABLE answer2 AS SELECT DISTINCT ON (bill_id) * FROM legislation;



-- exercise 3

-- create temp table with most of the required fields
CREATE TEMPORARY TABLE supplemental_data AS
  SELECT fullname,
         COUNT(*) AS total_bills, 
         SUM(sections) AS total_sections,
         AVG(sections) AS average_sections,
         MIN(intro_date) AS earliest_bill
  FROM answer2
  GROUP BY fullname;


-- create temp table with most_common_topic
-- technique stolen from https://gist.github.com/tototoshi/4376938#file-rownum-sql-L18
CREATE TEMPORARY TABLE most_common_topic AS
  SELECT * FROM (
    SELECT fullname, major_topic, row_number()
    OVER (PARTITION BY fullname 
              ORDER BY topic_count DESC, 
                       major_topic ASC) 
      AS rownum FROM topic_counts) tmp 
  WHERE rownum = 1;

ALTER TABLE most_common_topic DROP COLUMN rownum;

CREATE TEMPORARY TABLE answer3 AS
  SELECT *
  FROM supplemental_data 
  JOIN most_common_topic 
  USING (fullname)
  ORDER BY fullname;

