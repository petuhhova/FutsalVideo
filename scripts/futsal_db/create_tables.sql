DROP TABLE IF EXISTS country,competition,sources,season,competition_in_season,
competition_params,stage,round_stage_params,play_off_stage_params,
group_stage_params,group_in_stage,teams_in_group,teams_in_competition,
tour,matches,score,video_content,special_penalties,team,stadium;

CREATE TABLE IF NOT EXISTS country(
	country_id smallint GENERATED ALWAYS AS IDENTITY,
	country_name varchar(32) NOT NULL,
	country_flag_path varchar(256),
	
	CONSTRAINT pk_country PRIMARY KEY (country_id)
);

CREATE TABLE IF NOT EXISTS stadium(
	stadium_id smallint GENERATED ALWAYS AS IDENTITY ,
	stadium_name varchar(64) NOT NULL,
	country_id smallint NOT NULL,
	city varchar(32) NOT NULL,
	adress varchar(256),
	
	CONSTRAINT pk_stadium PRIMARY KEY (stadium_id)
);

CREATE TABLE IF NOT EXISTS team(
	team_id smallint GENERATED ALWAYS AS IDENTITY ,
	team_full_name varchar(64) NOT NULL,
	team_short_name varchar(32),
	country_id smallint NOT NULL,
	city varchar(32),
	stadium_id smallint,

	CONSTRAINT pk_team PRIMARY KEY (team_id),
	CONSTRAINT fk_team_country FOREIGN KEY (country_id) REFERENCES country,
	CONSTRAINT fk_team_stadium FOREIGN KEY (stadium_id) REFERENCES stadium

);
CREATE TABLE IF NOT EXISTS competition(
	competition_id smallint GENERATED ALWAYS AS IDENTITY,
	competition_name varchar(64) NOT NULL,
	country_id smallint,
	gender char NOT NULL,
	
	CONSTRAINT check_competition_gender CHECK (gender='f' OR gender='m'),
	
	CONSTRAINT pk_competition PRIMARY KEY (competition_id),
	CONSTRAINT fk_competition_country FOREIGN KEY (country_id) REFERENCES country
);

CREATE TABLE IF NOT EXISTS sources(
	competition_id smallint,
	results_source varchar(256),
	translations_source varchar(256),
	highlights_source varchar (256),
	
	CONSTRAINT pk_sources PRIMARY KEY (competition_id),
	CONSTRAINT fk_competition_sources FOREIGN KEY (competition_id) REFERENCES competition
);

CREATE TABLE IF NOT EXISTS season(
	season_id smallint GENERATED ALWAYS AS IDENTITY ,
	start_year smallint NOT NULL,
	end_year smallint,

	CONSTRAINT check_season_start_year CHECK (start_year BETWEEN 1990 AND 2040),
	CONSTRAINT check_season_end_year CHECK (end_year=start_year+1),
	
	CONSTRAINT pk_season PRIMARY KEY (season_id)
);

CREATE TABLE IF NOT EXISTS competition_in_season(
	competition_in_season_id smallint GENERATED ALWAYS AS IDENTITY ,
	season_id smallint NOT NULL,
	competition_id smallint NOT NULL,
	
	CONSTRAINT unique_competition_in_season_season_competition UNIQUE (season_id,competition_id),
	CONSTRAINT pk_competition_in_season PRIMARY KEY (competition_in_season_id),
	CONSTRAINT fk_competition_in_season_season FOREIGN KEY (season_id) REFERENCES season,
	CONSTRAINT fk_competition_in_season_competition FOREIGN KEY (competition_id) REFERENCES competition
);

CREATE TABLE IF NOT EXISTS competition_params(
	competition_in_season_id smallint,
	penalty_won_point bool NOT NULL DEFAULT FALSE,

	CONSTRAINT pk_competition_params PRIMARY KEY (competition_in_season_id),
	CONSTRAINT fk_competition_params_competition_in_season FOREIGN KEY (competition_in_season_id) REFERENCES competition_in_season
);

CREATE TABLE IF NOT EXISTS special_penalties(
	special_penalties_id int GENERATED ALWAYS AS IDENTITY NOT NULL,
	competition_in_season_id smallint NOT NULL,
	team_id smallint NOT NULL,
	penalty smallint NOT NULL,

	CONSTRAINT check_special_penalties_penalty CHECK (penalty>0),
	
	CONSTRAINT pk_special_penalties PRIMARY KEY (special_penalties_id),
	CONSTRAINT fk_special_penalties_team FOREIGN KEY (team_id) REFERENCES team,
	CONSTRAINT fk_special_penalties_competition_in_season FOREIGN KEY (competition_in_season_id) REFERENCES competition_in_season
);

CREATE TABLE IF NOT EXISTS stage(
	stage_id smallint GENERATED ALWAYS AS IDENTITY ,
	stage_number smallint NOT NULL,
	stage_type varchar(16) NOT NULL,
	competition_in_season_id smallint NOT NULL,

	CONSTRAINT check_stage_stage_number CHECK (stage_number>0),
	CONSTRAINT check_stage_stage_type CHECK (stage_type IN ('round','play-off','group')),
	CONSTRAINT unique_stage_stage_number_competition_in_season_id UNIQUE (stage_number,competition_in_season_id),
	
	CONSTRAINT pk_stage PRIMARY KEY (stage_id),
	CONSTRAINT fk_stage_competition_in_season FOREIGN KEY (competition_in_season_id) REFERENCES competition_in_season
);

CREATE TABLE IF NOT EXISTS round_stage_params(
	stage_id smallint,
	rounds_count smallint NOT NULL,

	CONSTRAINT check_round_stage_params_rounds_count CHECK (rounds_count>0),
	
	CONSTRAINT pk_round_stage_params PRIMARY KEY (stage_id),
	CONSTRAINT fk_round_stage_params_stage FOREIGN KEY (stage_id) REFERENCES stage
);

CREATE TABLE IF NOT EXISTS play_off_stage_params(
	stage_id smallint,
	rounds_count smallint NOT NULL,
	is_third_place_matches bool NOT NULL DEFAULT false,
	is_all_places_matches bool NOT NULL DEFAULT false,

	CONSTRAINT check_play_off_stage_params_rounds_count CHECK (rounds_count>0),
	
	CONSTRAINT pk_play_off_stage_params PRIMARY KEY (stage_id),
	CONSTRAINT fk_play_off_stage_params_stage FOREIGN KEY (stage_id) REFERENCES stage
);

CREATE TABLE IF NOT EXISTS group_stage_params(
	stage_id smallint,
	rounds_count smallint NOT NULL,
	groups_count smallint NOT NULL,
	group_name_type varchar(16) DEFAULT 'letters',

	CONSTRAINT check_group_stage_params_group_name_type CHECK (group_name_type='letters' OR group_name_type='numbers'),
	CONSTRAINT check_group_stage_params_rounds_count CHECK (rounds_count>0),
	CONSTRAINT check_group_stage_params_groups_count CHECK (groups_count>0),
	
	CONSTRAINT pk_group_stage_params PRIMARY KEY (stage_id),
	CONSTRAINT fk_group_stage_params_stage FOREIGN KEY (stage_id) REFERENCES stage
);

CREATE TABLE IF NOT EXISTS group_in_stage(
	group_in_stage_id smallint GENERATED ALWAYS AS IDENTITY ,
	stage_id smallint NOT NULL,
	group_number smallint NOT NULL,

	CONSTRAINT check_group_in_stage_group_number CHECK (group_number>0),
	CONSTRAINT unique_group_in_stage_group_number_stage_id UNIQUE (group_number,stage_id),
	
	CONSTRAINT pk_group_in_stage PRIMARY KEY (group_in_stage_id),
	CONSTRAINT fk_group_in_stage_stage FOREIGN KEY (stage_id) REFERENCES stage
);

CREATE TABLE IF NOT EXISTS teams_in_group(
	team_id smallint NOT NULL,
	group_in_stage_id smallint NOT NULL,
	
	CONSTRAINT pk_teams_in_group PRIMARY KEY (team_id,group_in_stage_id),
	CONSTRAINT fk_teams_in_group_team FOREIGN KEY (team_id) REFERENCES team,
	CONSTRAINT fk_teams_in_group_group_in_stage FOREIGN KEY (group_in_stage_id) REFERENCES group_in_stage
);

CREATE TABLE IF NOT EXISTS teams_in_competition(
	team_id smallint NOT NULL,
	competition_in_season_id smallint NOT NULL,
	
	CONSTRAINT pk_teams_in_competition PRIMARY KEY (team_id,competition_in_season_id),
	CONSTRAINT fk_teams_in_competition_team FOREIGN KEY (team_id) REFERENCES team,
	CONSTRAINT fk_teams_in_competition_competition_in_season FOREIGN KEY (competition_in_season_id) REFERENCES competition_in_season
);

CREATE TABLE IF NOT EXISTS tour(
	tour_id int GENERATED ALWAYS AS IDENTITY,
	tour_number smallint NOT NULL,
	stage_id smallint NOT NULL,

	CONSTRAINT check_tour_tour_number CHECK (tour_number > 0),
	CONSTRAINT unique_tour_tour_number_stage_id UNIQUE (tour_number,stage_id),
	
	CONSTRAINT pk_tour PRIMARY KEY (tour_id),
	CONSTRAINT fk_tour_stage FOREIGN KEY (stage_id) REFERENCES stage
);

CREATE TABLE IF NOT EXISTS score(
	score_id int GENERATED ALWAYS AS IDENTITY,
	goals1 smallint NOT NULL,
	goals2 smallint NOT NULL,
	penalty_goals1 smallint,
	penalty_goals2 smallint,

	CONSTRAINT pk_score PRIMARY KEY (score_id)
);

CREATE TABLE IF NOT EXISTS video_content(
	video_content_id int GENERATED ALWAYS AS IDENTITY ,
	highlights_link varchar(256),
	translation_link varchar(256),
	is_translation_paid bool DEFAULT false,

	CONSTRAINT pk_video_content PRIMARY KEY (video_content_id)
);
CREATE TABLE IF NOT EXISTS matches(
	match_id int GENERATED ALWAYS AS IDENTITY,
	team1_id smallint NOT NULL,
	team2_id smallint NOT NULL,
	score_id int UNIQUE,
	video_content_id int UNIQUE,
	match_date date,
	match_time timetz,
	stadium_id smallint,
	tour_id int NOT NULL,
	group_in_stage_id smallint,

	CONSTRAINT check_matches_team1_team2 CHECK (team1_id <> team2_id),
	
	CONSTRAINT pk_matches PRIMARY KEY (match_id),
	CONSTRAINT fk_mathches_score FOREIGN KEY (score_id) REFERENCES score,
	CONSTRAINT fk_mathches_video_content FOREIGN KEY (video_content_id) REFERENCES video_content,
	CONSTRAINT fk_mathches_tour FOREIGN KEY (tour_id) REFERENCES tour,
	CONSTRAINT fk_mathches_stadium FOREIGN KEY (stadium_id) REFERENCES stadium,
	CONSTRAINT fk_mathches_group_in_stage FOREIGN KEY (group_in_stage_id) REFERENCES group_in_stage
);

DROP FUNCTION IF EXISTS check_stage_type;

CREATE FUNCTION check_stage_type(_stage_id smallint, _stage_type varchar(32)) RETURNS BOOLEAN AS $$
BEGIN
  RETURN
    EXISTS(
      SELECT stage_type FROM stage 
      WHERE stage_id = _stage_id
      AND stage_type = _stage_type
      );
END
$$ LANGUAGE PLPGSQL;

ALTER TABLE ONLY round_stage_params
	ADD CONSTRAINT check_round_stage_params_stage_id CHECK (check_stage_type(stage_id,'round'));

ALTER TABLE ONLY play_off_stage_params
	ADD CONSTRAINT check_play_off_stage_params_stage_id CHECK (check_stage_type(stage_id,'play-off'));

ALTER TABLE ONLY group_stage_params
	ADD CONSTRAINT check_group_stage_params_stage_id CHECK (check_stage_type(stage_id,'group'));

ALTER TABLE ONLY group_in_stage
	ADD CONSTRAINT check_group_in_stage_stage_id CHECK (check_stage_type(stage_id,'group'));

DROP FUNCTION IF EXISTS	check_group_in_match,check_teams_in_match;

CREATE FUNCTION check_group_in_match(_tour_id int,_group_in_stage_id smallint) RETURNS BOOLEAN AS $$
DECLARE
	curr_stage_id smallint;
BEGIN
  SELECT stage_id FROM tour
  WHERE tour_id=_tour_id
  INTO curr_stage_id;
  
  IF check_stage_type(curr_stage_id,'group') THEN
  RETURN
	EXISTS(
	SELECT * FROM group_in_stage
    WHERE stage_id = curr_stage_id
	AND group_in_stage_id = _group_in_stage_id);
  END IF;
  RETURN _group_in_stage_id IS NULL;
END
$$ LANGUAGE PLPGSQL;

CREATE FUNCTION check_teams_in_match(_team1_id smallint,_team2_id smallint,_tour_id int,_group_in_stage_id smallint) RETURNS BOOLEAN AS $$
DECLARE
	curr_comp smallint;
	count_teams smallint;
BEGIN
	SELECT competition_in_season_id FROM tour
	JOIN stage ON stage_id
    WHERE tour_id = _tour_id
	INTO curr_comp;

	IF _group_in_stage_id IS NULL THEN
		SELECT COUNT(*) FROM teams_in_competition
		WHERE competition_in_season=curr_comp
		AND team_id=_team1_id OR team_id=_team2_id
		INTO count_teams;
	ELSE
		SELECT COUNT(*) FROM teams_in_group
		WHERE group_in_stage_id=_group_in_stage_id
		AND team_id=_team1_id OR team_id=_team2_id
		INTO count_teams;
	END IF;

	RETURN count_teams=2;
END
$$ LANGUAGE PLPGSQL;

ALTER TABLE ONLY matches
	ADD CONSTRAINT check_matches_right_group CHECK (check_group_in_match(tour_id,group_in_stage_id));

ALTER TABLE ONLY matches
	ADD CONSTRAINT check_matches_right_teams CHECK (check_teams_in_match(team1_id,team2_id,tour_id,group_in_stage_id));