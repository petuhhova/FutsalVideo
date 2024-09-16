import psycopg2
from decouple import config
from scripts.parser.parse_functions import *

# Создать класс DB_updator c потомками по странам
# функции с request и connection вынести отдельно
# чисто функции парсинга сайтов тоже (скорее тоже отдельный класс Parser с потомками по страном)

def create_connection_to_project_DB():
    connection = None
    try:
        connection = psycopg2.connect(
            database=config("DB_NAME"),
            user=config("DB_USER"),
            password=config("DB_PASSWORD"),
            host=config("DB_HOST"),
            port=config("DB_PORT"),
        )
        print("Connection to PostgreSQL DB successful")
    except psycopg2.OperationalError as e:
        print(f"The error '{e}' occurred")
    return connection

#parent
def update_db(update_function,params):
    connection=create_connection_to_project_DB()
    if connection is None:
        return
    update_function(connection,**params)
    connection.commit()
    connection.close()

#parent
def update_source_comp_id_for_country(connection,country_name):
    cursor=connection.cursor()
    get_country_results_sources="""SELECT competition_id,results_source FROM sources
    JOIN  competition USING(competition_id)
    JOIN country USING(country_id)
    WHERE country_name='{}'""".format(country_name)
    cursor.execute(get_country_results_sources)
    res=cursor.fetchall()
    for comp_id, url in res:
        src_comp_id=get_source_comp_id(url)
        if src_comp_id is None:
            continue
        update_command="""UPDATE sources
        SET source_competition_id={}
        WHERE competition_id={};""".format(src_comp_id,comp_id)
        cursor.execute(update_command)

def get_team_id(connection,team_full_name):
    cursor = connection.cursor()
    cursor.execute("""SELECT team_id FROM team WHERE team_full_name ='{}'""".format(team_full_name))
    res=cursor.fetchall()
    if res:
        return res[0]

def insert_team(connection,team_full_name,team_short_name=None,country_id=None,city=None,stadium_id=None):
    cursor=connection.cursor()
    cursor.execute("""INSERT INTO team (team_full_name,team_short_name,country_id,city,stadium_id)
    VALUES ('{}',{},{},{},{}) RETURNING team_id;""".format(team_full_name,
                                                           '\'{}\''.format(team_short_name) if not team_short_name is None else 'DEFAULT',
                                                           country_id if not country_id is None else 'DEFAULT',
                                                           '\'{}\''.format(city) if not city is None else 'DEFAULT',
                                                           stadium_id if not stadium_id is None else 'DEFAULT'))

    return cursor.fetchone()[0]

def set_teams_in_competition(connection,cis_id,src_comp_id,year,country_id):
    cursor=connection.cursor()
    cursor.execute('DELETE FROM teams_in_competition WHERE competition_in_season_id={};'.format(cis_id))
    teams=get_teams_in_competition(src_comp_id,year)
    for team in teams:
        team_id=get_team_id(connection, team)
        if team_id is None:
            team_id=insert_team(connection,team,country_id=country_id)
        cursor.execute("""INSERT INTO teams_in_competition (team_id,competition_in_season_id)
        VALUES (%s,%s)""",(team_id,cis_id))

def count_tours(connection,stage_id,stage_type,cis_id):
    cursor=connection.cursor()
    cursor.execute("""SELECT rounds_count
    FROM {}_stage_params
    WHERE stage_id={}""".format(stage_type,stage_id))
    rounds_count = cursor.fetchone()[0]
    if stage_type=='playoff':
        return rounds_count
    elif stage_type=='round':
        cursor.execute("""SELECT COUNT(*)
         FROM teams_in_competition
         WHERE competition_in_season_id={}
         GROUP BY competition_in_season_id;""".format(cis_id))
        teams_count=cursor.fetchone()[0]
        tours_in_round=teams_count if teams_count%2==1 else teams_count-1
        return  tours_in_round*rounds_count

def insert_matches_in_tour(connection,tour_id,source_comp_id,year,stage_type,tour_number):
    get_matches_info(source_comp_id,year,stage_type,tour_number)
#child
def set_matches_for_competition_in_season(connection,competition_id,season_id,country_id):
    cursor=connection.cursor()
    cursor.execute("""SELECT competition_in_season_id,source_competition_id,start_year,end_year FROM competition_in_season as cns
    JOIN sources USING(competition_id)
    JOIN season USING (season_id)
    WHERE cns.competition_id={} and cns.season_id={};""".format(competition_id,season_id))
    res=cursor.fetchall()
    if not res:
        return
    cis_id,src_comp_id,start_year,end_year=res[0]
    if src_comp_id is None:
        return
    year=start_year if end_year is None else end_year
    set_teams_in_competition(connection,cis_id,src_comp_id,year,country_id)
    cursor.execute("""SELECT stage_id,stage_type
    FROM stage
    WHERE competition_in_season_id = %(int)s ;""",{'int':cis_id})
    for stage_id,stage_type in cursor.fetchall():
        for tour_number in range(1,count_tours(connection,stage_id,stage_type,cis_id)+1):
            cursor.execute("""INSERT INTO tour (tour_number,stage_id)
            VALUES ({},{})
            RETURNING tour_id""".format(tour_number,stage_id))
            tour_id=cursor.fetchone()[0]
            insert_matches_in_tour(connection,tour_id,src_comp_id,year,stage_type,tour_number)

#parent
def set_matches_for_country(connection,country_name):
    cursor = connection.cursor()
    cursor.execute("""SELECT country_id,competition_id,season_id FROM competition_in_season
    JOIN competition USING(competition_id)
    JOIN country USING(country_id)
    WHERE country_name='{}'""".format(country_name))
    for country_id,comp_id,season_id in cursor.fetchall():
        set_matches_for_competition_in_season(connection,comp_id,season_id,country_id)

#update_db(set_matches_for_country,{'country_name':'Испания'})