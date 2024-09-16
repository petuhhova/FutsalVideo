TRUNCATE country RESTART IDENTITY CASCADE;
TRUNCATE season RESTART IDENTITY CASCADE;
INSERT INTO country(country_name)
VALUES ('Испания');

INSERT INTO competition (competition_name,country_id,gender) VALUES
	('Примера',1,'m'),
	('Кубок короля',1,'m'),
	('Суперкубок Испании',1,'m'),
	('Примера',1,'f'),
	('Кубок королевы',1,'f'),
	('Суперкубок Испании',1,'f');

INSERT INTO sources(competition_id,results_source) VALUES
	(1,'https://rfef.es/es/competiciones/primera-division-fs'),
	(2,'https://rfef.es/es/competiciones/copa-del-rey'),
	(3,'https://rfef.es/es/competiciones/supercopa-de-espana-futsal'),
	(4,'https://rfef.es/es/competiciones/primera-futbol-sala-iberdrola'),
	(5,'https://rfef.es/es/competiciones/copa-de-la-reina-fs'),
	(6,'https://rfef.es/es/competiciones/supercopa-de-espana-futsal-femenina');

SELECT * from competition JOIN sources USING (competition_id);

INSERT INTO season(start_year,end_year) VALUES
	(2023,2024),
	(2024,2025);

SELECT competition_id,season_id FROM competition CROSS JOIN season;

INSERT INTO competition_in_season(competition_id,season_id)
	SELECT competition_id,season_id FROM competition CROSS JOIN season;

INSERT INTO competition_params(competition_in_season_id)
	SELECT competition_in_season_id FROM competition_in_season;
	
SELECT * FROM competition_in_season JOIN season USING (season_id) JOIN competition USING(competition_id);

TRUNCATE stage RESTART IDENTITY CASCADE;
INSERT INTO stage(stage_number,stage_type,competition_in_season_id) VALUES
	(1,'round',1),
	(2,'playoff',1),
	(1,'playoff',2),
	(1,'playoff',3),
	(1,'round',4),
	(2,'playoff',4),
	(1,'playoff',5),
	(1,'playoff',6);
	
INSERT INTO round_stage_params(stage_id,rounds_count) VALUES
	(1,2),
	(5,2);

TRUNCATE playoff_stage_params;
INSERT INTO playoff_stage_params(stage_id,rounds_count,is_third_place_matches) VALUES
	(2,5,FALSE),
	(3,8,FALSE),
	(4,2,FALSE),
	(6,3,TRUE),
	(7,6,FALSE),
	(8,2,FALSE);

SELECT country_name, competition_name,gender,concat(start_year,'/',end_year) as season,stage_type as stage FROM stage
LEFT JOIN round_stage_params USING (stage_id)
LEFT JOIN playoff_stage_params USING (stage_id)
JOIN competition_in_season USING (competition_in_season_id)
JOIN competition USING (competition_id)
JOIN season USING (season_id)
JOIN country USING (country_id)
ORDER BY competition_id;
