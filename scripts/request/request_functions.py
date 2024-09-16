import requests

def get_request(url,params={}):
    try:
        user_agent = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36'
        r = requests.get(url, headers={'User-Agent': user_agent},params=params,timeout=10)
        return r
    except Exception as e:
        print(e)