Видео контент — API 1.3 3 documentation

#
  
Содержание  
-

Видео контент  
  -

Типы видео контента
  -

Жанры
  -

Страны
  -

Видео контент
  -

Поиск
  -

Похожие видео
  -

Список медиа-контента
  -

Ссылки на субтитры и видео-файлы для media
  -

Ссылка на видео-файл по имени файла
  -

Голосование за видео
  -

Комментарии для фильма/эпизода
  -

Трейлер к контенту
  -

Shortcut - свежие видео
  -

Shortcut - горячие видео
  -

Shortcut - популярные видео
  
##
  
**Видео контент условно разделен на типы:**

-

**movie** - Фильмы
-

**serial** - Сериалы
-

**3D** - 3D Фильмы
-

**concert** - Концерты
-

**documovie** - Документальные фильмы
-

**docuserial** - Документальные сериалы
-

**tvshow** - ТВ Шоу

Запрос:

```
GET https://api.service-kp.com/v1/types

```
  
Ответ:

```
HTTP/1.1 200 OK
Content-Type: application/json

[
    {
        'id': 'movie',
        'title': 'Фильмы',
    },
    {
        'id': 'serial',
        'title': 'Сериалы'
    }
]

```

##
  
**Типы жанров:**

-

**movie** - жанры типов видео контента **movie**, **serial**, **3D** (Фильмов и Сериалов)
-

**music** - жанры типов видео контента **concert** (Концерты)
-

**docu** - жанры типов видео контента **documovie**, **docuserial** (Документальные фильмы и сериалы)

Жанры, как и контент, разделены по типам. Видео контент с типом **movie**, **serial**, **3d** может принадлежать только жанрам с типом **movie** и т.д.

Запрос:

```
GET https://api.service-kp.com/v1/genres

```

**Параметры запроса:**

-

**[type]** - фильтр по типу жанров, по умолчанию возвращаются все жанры. Указать можно только один из нижеперечисленных
  -

movie - Обощенный тип
  -

docu  - Обобщенный тип
  -

music  - Обобщенный тип
  -

tvshow  - Обобщенный тип
  -

movie
  -

documovie
  -

serial
  -

docuserial
  -

tvshow
  -

concert
  -

3d
  -

4k

Ответ:

```
HTTP/1.1 200 OK
Content-Type: application/json

[
    {
        'id': 1,
        'title': 'Комедия',
        'type': 'movie'
    },
    {
        'id':10,
        'title': 'Катастрофа',
        'type': 'docu'
    }
    {
        'id': 13,
        'title': Rock,
        'type': music
    }
]

```

##

Запрос:

```
GET https://api.service-kp.com/v1/countries

```
  
Ответ:

```
HTTP/1.1 200 OK
Content-Type: application/js

[
    {
        'id': 1,
        'title': 'США',
    }
]

```

##

Запрос:

```
GET https://api.service-kp.com/v1/items

```

**Параметры запроса:**

-

**[type]** - Типы видео контента
-

**[title]** - Поиск по заголовку, минимум 3 символа. Выборка по типу LIKE ‘$ASD’
-

**[genre]** - id жанра. Для множественного поиска список через запятую.
-

**[country]** - id страны. Для множественного поиска список через запятую.
-

**[year]** - Год. Для поиска в промежутке year1-year2
-

**[finished]** - 0/1. Статус сериала, завершен/снимается.
-

**[actor]** - Имена актеров чере запятую или +(плюс), “Actor1,Actor2+Actor3” - ищет (Actor1 OR (Actor2 AND Actor3))
-

**[director]** - Имена режисеров чере запятую или +(плюс), “Actor1,Actor2+Actor3” - ищет (Actor1 OR (Actor2 AND Actor3))
-

**[letter]** - Поиск по первой букве в названиях(рус,анг) фильма
-

**[conditions]** - Массив простых условий для фильтра. Доступные поля как и в сортировке. year <= 100. Объединение условий через AND
-  

****[force]** - Массив для пропуска пользовательских настроек фильтрации**

-

**quality** - Пропускаем проверку на сомнительное качество
  -

**advert**  - Пропускаем проверку на контент с рекламой
  -

**erotic**  - Пропускаем проверку на эротический контент

-

**[sort]** - Сортировка, по умолчанию ‘updated-‘. Без знака ‘-‘ сортируется по возрастанию(ASC), со знаком ‘-‘(минус) по убыванию(DESC). Можно указать можество полей через запятую,.
  -

id
  -

year
  -

title
  -

created
  -

updated
  -

rating
  -

views
  -

watchers

-

**[quality]** - Массив идентификаторов качеств

Ответ:

```
HTTP/1.1 200 OK
Content-Type: application/js

{
    'items':[
        {
            'id': 1,
            'title': 'Название / Оригинальное название',
            'type': 'movie', // тип контента
            'subtype': 'multi', // Подтип контента, бывают многосерийные фильмы, концерты
            'year': 2006,
            'cast': 'Актёр 1, Актёр 2',
            'director': 'Режиссёр 1, Режиссёр 2',
            'voice': 'Любительский одноголосый, Оригинал',
            'duration': [
                'average': 123, // Средняя продолжительность для сериалов, полная для фильмов
                'total': 123 //Общая продолжительность фильма, сериала
            ],
            'langs': 2, //Количество аудио дорожек
            'ac3': 0, // Присутствуют или нет AC-3 аудио
            'subtitles': 3, // Количество субтитров
            'quality': 1080, // Качество фильма, для сериалов берется наибольшее количество серий с определенным качеством
            'genres': [
                {
                    'id': 1,
                    'title': 'Комедия'
                },
                {
                    'id': 2,
                    'title': 'Ужасы'
                }
            ],
            'countries': [
                {
                    'id': 1,
                    'title': 'США'
                }
            ],
            'plot': 'Описание фильма',
            'tracklist': [
                {
                    'artist' => 'Исполнитель',
                    'title' => 'Название композиции',
                    'url' => 'ссылка на аудио файл',
                }
            ],
            'imdb': 123,
            'imdb_rating': 123,
            'imdb_votes': 123,
            'kinopoisk': 123,
            'kinopoisk_rating': 123,
            'kinopoisk_votes': 123,
            'rating': 456,
            'views': 15,
            'comments': 5,
            'finished' : false, // Для сериалов: true - окончен, false - снимается
            'advert' : true, // Присутствуют посторонние вставки рекламы
            'in_watchlist': true, // Подписан ли пользователь на сериал
            'subscribed': true, // Подписан ли пользователь на сериал, alias in_watchlist
            'posters': [
                'small': 'http://kino.pub/media/poster/item/small/1.jpg',
                'medium': 'http://kino.pub/media/poster/item/medium/1.jpg';
                'big': 'http://kino.pub/media/poster/item/big/1.jpg';
            ],
            'trailer': {
                'id': 'udNj459jn',
                'url': 'http://www.youtube.com/watch?v=udNj459jn',
            }
        }
    ],
    'pagination': {
        'total': 1,
        'current':1,
        'perpage':1
    }
}

```

##

Поиск производится по полям title, director, cast

Запрос:

```
GET https://api.service-kp.cnom/v1/items/search?q=termi

```

**Параметры запроса::**

-

**q** - Строка поиска
-

**[type]** - Типы видео контента, тип контента
-

**[field]** - поиск только в одном из полей title,director,cast. Если не указанно, поиск по всем полям.
-

**perpage** - кол-во результатов на страницу. По умолчанию 40.
-

**sectioned** - 0/1 (по умолчанию 0). Разбивает запрос по секциям type.

Ответ без sectioned:

```
HTTP/1.1 200 OK
Content-Type: application/js

{
    'status': 200,
    'items': [],
    'pagination': {},
}

```
  
Ответ c sectioned=1:

```
HTTP/1.1 200 OK
Content-Type: application/js

{
    'status': 200,
    'items': [
        'movie': [
            'items': [],
            'pagination': {},
        ],
    ],
}

```

##

Запрос:

```
GET https://api.service-kp.com/v1/items/similar

```

**Параметры запроса:**

-

**id** - Идентификатор item для которого проивзодится поиск похожих
  
**Ответ::**

Список видео

##

Запрос:

```
GET https://api.service-kp.com/v1/items/<item-id>

```

**Параметры запроса:**

-

<s>[exclude_info]</s> - 1 исключить из ответа секцию item. Опция удалена
-

**[nolinks]** - 1 исключает ссылки на видео (значение по умолчания - 0). У больших сериалов ссылки занимают львиную долю объема ответа причем большинство из этих ссылок не используется в рамках 1 запроса. В следующей версии значение по умолчанию станет 1, а через версию параметр станет недоступным и ссылки нужно будет всегда получать в отдельном запросе.

Ответ для типов movie, documovie, concert:

```
HTTP/1.1 200 OK
Content-Type: application/js

{
    'item': {
        // Набор данных из "https://api.service-kp.com/v1/items". Отсутствует, если exclude_info=1
        videos: [
            {
                'title': 'Название видео',
                'thumbnail': 'http://kino.pub/media/thumbnail/12345.jpg',
                'duration': 1234, //Время в секундах
                'watched' : 1, // Статус просмотра эпизода: -1 не смотрели вообще, 0 - начали смотреть, 1 - просмотрели
                'watching' : {
                    'status': -1, // Статус просмотра эпизода: -1 не смотрели вообще, 0 - начали смотреть, 1 - просмотрели
                    'time': 1234  // Время просмотра в секундах
                },
                'tracks': '1,2,3,4' // Номера аудио-дорожек
                'subtitles': [
                    {
                        'lang': 'eng',
                        'shift': 0, // Смещение относительно видео-потока
                        'embed': true, // Доступно в файле-исходнике, вшиты в него отдельным стримом
                        'url': 'http://url/to/file.srt',
                    }
                ],
                "audios": [
                   {
                       "id": 15510,
                       "index": 1,
                       "codec": "aac",
                       "channels": 2,
                       "lang": "ukr",
                       "type": {
                           "id": 2,
                           "title": "Многоголосый",
                           "short_title": "MVO"
                       },
                       "author": {
                           "id": 7,
                           "title": "Дохалов",
                           "short_title": null
                       }
                   },
                   {
                       "id": 15504,
                       "index": 2,
                       "codec": "aac",
                       "channels": 2,
                       "lang": "rus",
                       "type": {
                           "id": 2,
                           "title": "Многоголосый",
                           "short_title": "MVO"
                       },
                       "author": {
                           "id": 1,
                           "title": "Видеосервис",
                           "short_title": null
                       }
                   },
                   {
                       "id": 15505,
                       "index": 3,
                       "codec": "aac",
                       "channels": 2,
                       "lang": "rus",
                       "type": {
                           "id": 2,
                           "title": "Многоголосый",
                           "short_title": "MVO"
                       },
                       "author": {
                           "id": 2,
                           "title": "BD CEE",
                           "short_title": null
                       }
                   },
                   {
                       "id": 15508,
                       "index": 4,
                       "codec": "aac",
                       "channels": 2,
                       "lang": "rus",
                       "type": {
                           "id": 5,
                           "title": "Авторский",
                           "short_title": "AVO"
                       },
                       "author": {
                           "id": 4,
                           "title": "Гаврилов",
                           "short_title": null
                       }
                   },
                   {
                       "id": 15512,
                       "index": 10,
                       "codec": "ac3",
                       "channels": 6,
                       "lang": "rus",
                       "type": {
                           "id": 2,
                           "title": "Многоголосый",
                           "short_title": "MVO"
                       },
                       "author": {
                           "id": 1,
                           "title": "Видеосервис",
                           "short_title": null
                       }
                   }
                ],
                'files': [
                    {
                        'w': 720,
                        'h': 306,
                        'quality': '420p',
                        'url': {
                            'http': 'http://url/to/http/stream.mp4',
                            'hls': 'http://url/to/hls/stream/playlist.m3u8'
                        },
                    },
                    {
                        'w': 960,
                        'h': 480,
                        'quality': '720p'
                        'url': {
                            'http': 'http://url/to/http/stream.mp4',
                            'hls': 'http://url/to/hls/stream/playlist.m3u8'
                        },
                    }
                ]
            }
        ]
    },
}

```
  
Ответ для типов serial, docuserial:

```
HTTP/1.1 200 OK
Content-Type: application/js

{
    'item': {
        // Набор данных из "https://api.service-kp.com/v1/items". Отсутствует, если exclude_info=1
        seasons: [
            {
                'title': 'Название сезона',
                'number': 1,
                'episodes': [
                    {
                        'title': 'Название видео',
                        'thumbnail': 'http://kino.pub/media/thumbnail/12345.jpg',
                        'duration': 1234, //Время в секундах
                        'audios': [],
                        'files': [
                            {
                                'w': 720,
                                'h': 306,
                                'quality': '420p',
                                'url': {
                                    'http': 'http://url/to/http/stream.mp4',
                                    'hls': 'http://url/to/hls/stream/playlist.m3u8'
                                },
                            },
                            {
                                'w': 960,
                                'h': 480,
                                'quality': '720p'
                                'url': {
                                    'http': 'http://url/to/http/stream.mp4',
                                    'hls': 'http://url/to/hls/stream/playlist.m3u8'
                                },
                            }
                        ]
                    }
                ]
            }
        ]
    },
}

```

##

Внимание, поле status больше не используется в успешных ответах.

Запрос:

```
GET https://api.service-kp.com/v1/items/media-links?mid=<media_id>

```

**Параметры запроса:**

-

**mid** - Идентификатор media

Ответ:

```
HTTP/1.1 200 OK
Content-Type: application/js

    {
            "files": [
                    {
                            "codec": "h264",
                            "w": 1920,
                            "h": 1080,
                            "quality": "1080p",
                            "quality_id": 3,
                            "file": "/b/8c/diBAgF24FkaNBwPpB.mp4",
                            "urls": {
                                    "http": "https://host/token/file.mp4",
                                    "hls": "https://host/token/file.mp4",
                                    "hls4": "https://host/token/file.mp4",
                                    "hls2": "https://host/token/file.mp4"
                            }
                    },
                    {
                            "codec": "h264",
                            "w": 1280,
                            "h": 720,
                            "quality": "720p",
                            "quality_id": 2,
                            "file": "/7/b3/5qx0TBPotyBf0nsrZ.mp4",
                            "urls": {
                                    "http": "https://host/token/file.mp4",
                                    "hls": "https://host/token/file.mp4",
                                    "hls4": "https://host/token/file.mp4",
                                    "hls2": "https://host/token/file.mp4"
                            }
                    },
            ],
            "subtitles": [
                    {
                            "lang": "eng",
                            "shift": 0,
                            "embed": true,
                            "file": "/a/71/29725.srt",
                            "url": "https://host/token/file.srt"
                    },
                    {
                            "lang": "rus",
                            "shift": 0,
                            "embed": true,
                            "file": "/2/2a/29859.srt",
                            "url": "https://host/token/file.srt"
                    }
            ]
    }

```

##

Внимание, поле status больше не используется в успешных ответах.

Запрос:

```
GET https://api.service-kp.com/v1/items/media-video-link?file=/path/to/file&type=http

```

**Параметры запроса:**

-

**file** - Путь к файлу
-

**type** - Тип потока, http|hls|hls2|hls4

Ответ:

```
HTTP/1.1 200 OK
Content-Type: application/js

    {
            "url": "https://host/hls4/client/token/path/to/file.mp4?loc=de"
    }

```

##

Запрос:

```
GET https://api.service-kp.com/v1/items/vote?id=111&like=1

```

**Параметры запроса:**

-

**id** - идентификатор item
-

**like** - 1: нравится, 0: не нравится

Ответ:

```
HTTP/1.1 200 OK
Content-Type: application/js

    {
    "voted": true, // засчитался ли голос
    "total": "5", // всего голосов
    "positive": "5", // позитивных голосов
    "negative": "0", // негативных голосов
    "rating": 5 // подсчитанный рейтинг: позитивные минус негативные
    }

```

##

Запрос:

```
GET https://api.service-kp.com/v1/items/comments?id=<item_id>

```

**Параметры запроса:**

-

**id** - Идентификатор фильма/сериала/etc

Ответ:

```
HTTP/1.1 200 OK
Content-Type: application/js

{
    "status":200,
    "item" : {
        "id":1235,
        "title":"Книга крови /  Book of Blood"
    },
    "comments":[
       {
           "id":1,
           "depth":0,
           "unread":false,
           "deleted":false,
           "message":"comment message",
           "created":1234234234,
           "rating":"0",
           "user":{
               "id":123,
               "name":"UserName",
               "avatar":"http://gravatar.com/avatar/asdasdasdas"
            }
        },
     ]
 }

```

##

Запрос:

```
GET https://api.service-kp.com/v1/items/trailer?[id=123 | sid=l_5JsdfkjN34]

```
  
Ответ:

```
HTTP/1.1 200 OK
Content-Type: application/js

[
    {
        'status': 200,
        'trailer': {
            'id': 'l_54Jsdfkn',
            'url': 'http://youtube.com/watch?v=l_54Jsdfkn',
            'files': [
                {
                    'url': 'https://url.to.file',
                    'quality': 360,
                    'width: 480,
                    'height': 360,
                },
            ],
        }
    }
]

```

##

Запрос:

```
GET https://api.service-kp.com/v1/items/fresh

```

**Параметры запроса:**

-

**type** - Типы видео контента
-

**[page=0]** - текущая страница
-

**[perpage=25]** - количество на страницу
  
**Ответ::**

Видео контент

##

Запрос:

```
GET https://api.service-kp.com/v1/items/hot

```

**Параметры запроса:**

-

**type** - Типы видео контента
-

**[page=0]** - текущая страница
-

**[perpage=25]** - количество на страницу
  
**Ответ::**

Видео контент

##

Запрос:

```
GET https://api.service-kp.com/v1/items/popular

```

**Параметры запроса:**

-

**type** - Типы видео контента
-

**[page=0]** - текущая страница
-

**[perpage=25]** - количество на страницу
  
**Ответ::**

Видео контент
