DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM "Summaries" WHERE "Description" = 'Freezing') THEN
    INSERT INTO "Summaries" ("Description") VALUES ('Freezing');
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM "Summaries" WHERE "Description" = 'Bracing') THEN
    INSERT INTO "Summaries" ("Description") VALUES ('Bracing');
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM "Summaries" WHERE "Description" = 'Chilly') THEN
    INSERT INTO "Summaries" ("Description") VALUES ('Chilly');
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM "Summaries" WHERE "Description" = 'Cool') THEN
    INSERT INTO "Summaries" ("Description") VALUES ('Cool');
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM "Summaries" WHERE "Description" = 'Mild') THEN
    INSERT INTO "Summaries" ("Description") VALUES ('Mild');
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM "Summaries" WHERE "Description" = 'Warm') THEN
    INSERT INTO "Summaries" ("Description") VALUES ('Warm');
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM "Summaries" WHERE "Description" = 'Balmy') THEN
    INSERT INTO "Summaries" ("Description") VALUES ('Balmy');
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM "Summaries" WHERE "Description" = 'Hot') THEN
    INSERT INTO "Summaries" ("Description") VALUES ('Hot');
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM "Summaries" WHERE "Description" = 'Sweltering') THEN
    INSERT INTO "Summaries" ("Description") VALUES ('Sweltering');
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM "Summaries" WHERE "Description" = 'Scorching') THEN
    INSERT INTO "Summaries" ("Description") VALUES ('Scorching');
  END IF;
END $$;
