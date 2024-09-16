
DROP FUNCTION IF EXISTS check_stage_type CASCADE;

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

ALTER TABLE ONLY playoff_stage_params
	ADD CONSTRAINT check_play_off_stage_params_stage_id CHECK (check_stage_type(stage_id,'playoff'));

ALTER TABLE ONLY group_stage_params
	ADD CONSTRAINT check_group_stage_params_stage_id CHECK (check_stage_type(stage_id,'group'));

ALTER TABLE ONLY group_in_stage
	ADD CONSTRAINT check_group_in_stage_stage_id CHECK (check_stage_type(stage_id,'group'));

DROP FUNCTION IF EXISTS	check_group_in_match, check_teams_in_match CASCADE;

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
		WHERE competition_in_season_id=curr_comp
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