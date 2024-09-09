from django.shortcuts import render
from django.http import HttpResponse, HttpResponseNotFound, Http404
# Create your views here.
def index(request):
    return HttpResponse("MainPage")

def countries(request,country):
    #request.POST
    if request.GET:
        if 'country' in request.GET:
            return HttpResponse(f"<p>{request.GET['country']}<p>")
    return HttpResponse(f"<p>{country}<p>")

def archive(request,year):
    if int(year) > 2024:
        raise Http404()
    return HttpResponse(f"Архив <p>{year}<p>")

def pageNotFound(request,exception):
    return HttpResponseNotFound("<h1>Страница не найдена</h1>")