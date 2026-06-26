Справочники — API 1.3 3 documentation

#
  
Содержание  
-

Справочники  
  -

Список локаций сервера
  -

Список типов стриминга
  -

Список типов переводов
  -

Список авторов озвучек/переводов
  -

Список качеств видео
  
##

Запрос:

```
GET https://api.service-kp.com/v1/references/server-location

HTTP/1.1 200 OK
Content-Type: application/json

{
  'status': 200,
  'items': [
     {
        'id': 1,
        'location': 'de',
        'name': 'Германия',
     }
  ],
}

```

##

Запрос:

```
GET https://api.service-kp.com/v1/references/streaming-type

HTTP/1.1 200 OK
Content-Type: application/json

{
  'status': 200,
  'items': [
     {
        'id': 1,
        'code': 'hls4',
        'name': 'HLS4',
        'description': 'Description'
     }
  ],
}

```

##

Запрос:

```
GET https://api.service-kp.com/v1/references/voiceover-type

HTTP/1.1 200 OK
Content-Type: application/json

{
  'status': 200,
  'items': [
     {
        "id": 1,
        "title": "Дубляж",
        "short_title": "DUB"
     },
  ],
}

```

##

Запрос:

```
GET https://api.service-kp.com/v1/references/voiceover-author

HTTP/1.1 200 OK
Content-Type: application/json

{
  'status': 200,
  'items': [
     {
        "id": 1,
        "title": "Видеосервис",
        "short_title": null
     },
  ],
}

```

##

Запрос:

```
GET https://api.service-kp.com/v1/references/video-quality

HTTP/1.1 200 OK
Content-Type: application/json

{
  'status': 200,
  'items': [
     {
        "id": 1,
        "title": "480p",
        "quality": 480,
     },
     {
        "id": 2,
        "title": "720p",
        "quality": 720,
     },
  ],
}

```
