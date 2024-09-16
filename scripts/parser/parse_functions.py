import re
from bs4 import BeautifulSoup
import time
from scripts.request.request_functions import *


def get_source_comp_id(url):
    r = get_request(url)
    if r is None:
        return
    pat="(?<=&competition=)[0-9]+"
    res=re.search(pat,r.text)
    if not res is None:
        return int(res.group())

def get_teams_in_competition(src_comp_id,year):
    url = "https://widgets.besoccerapps.com/scripts/widgets"
    params={'type':'clasification_ajax','competition':src_comp_id, 'year':year,'round':1,'group':'1','style':'rfef',
            'hidden_combo':1,'hidden_leyend':1,'hidden_season':1,'show_title':0,'show_links':0,'basic':1}
    r=get_request(url,params)
    if r is None:
        return []
    parser = BeautifulSoup(r.text,'html.parser')
    teams=[res.string for res in parser.find_all(itemprop='name')]
    return teams

def get_matches_info(src_comp_id,year,stage_type,tour_number):
    url="https://widgets.besoccerapps.com/scripts/widgets"
    params = {'type': 'matchs', 'competition': src_comp_id, 'year': year, 'round': tour_number, 'group': stage_type,
              'style': 'rfef','show_title': 0, 'show_links': 0, 'basic': 1,'show_amp':1}
    r = get_request(url, params)
    if r is None:
        return []
    print(r.url)
    time.sleep(1)
    parser = BeautifulSoup(r.text, 'html.parser')