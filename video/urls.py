from django.urls import path, re_path
from .views import *

urlpatterns = [
    path('', index),
    path('<slug:country>/',countries),
    path('<slug:country>/',countries),
    re_path(r'^archive/(?P<year>[0-9]{4})', archive),
]