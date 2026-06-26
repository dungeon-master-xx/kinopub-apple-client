Подборки — API 1.3 3 documentation

#
  
Содержание  
-

Подборки  
  -

Список подборок
  -

Список фильмов в подбороке
  
##
  
**Параметры запроса:**

-

**[title]** - Поиск по заголовку, минимум 3 символа. Выборка по типу LIKE ‘$ASD’
-  

****[sort]** - Сортировка, по умолчанию ‘updated-‘. Без знака ‘-‘ сортируется по возрастанию(ASC),**

-

id
  -

title
  -

views
  -

watchers
  -

created
  -

updated

-

**[perpage]** - Пагинация, кол-во на одной странице
-

**[page]** - Пагинация, текущая страница

Запрос:

```
GET https://api.service-kp.com/v1/collections

```
  
Ответ:

```
HTTP/1.1 200 OK
Content-Type: application/json

[
    'status': 200,
    'items': [
        {
            'id': 1,
            'title': 'Семейные',
            'watchers': 19,
            'views' => 123,
            'created': 12345667,
            'updated': 12345678,
            'posters': [
                'small' => 'http://media.service-kp.com/small/1.jpg',
                'medium' => 'http://media.service-kp.com/small/1.jpg',
                'big' => 'http://media.service-kp.com/small/1.jpg',
            ],
        }
    ]
]

```

##
  
**Параметры запроса:**

-

**id** - id подборки

Запрос:

```
GET https://api.service-kp.com/v1/collections/view?id=1

```
  
Ответ:

```
HTTP/1.1 200 OK
Content-Type: application/json

[
    'status': 200,
    'collection': {
        'id': 1,
        'title': 'Семейные',
        'watchers': 19,
        'views' => 123,
        'created': 12345667,
        'updated': 12345678,
        'posters': [
            'small' => 'http://media.service-kp.com/small/1.jpg',
            'medium' => 'http://media.service-kp.com/small/1.jpg',
            'big' => 'http://media.service-kp.com/small/1.jpg',
        ],
    },
    'items': [ ]
]

```
  
Описание полей ‘items’ смотрите тут
