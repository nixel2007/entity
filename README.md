# entity - OneScript Persistence API

<a id="header" />

[![GitHub release](https://img.shields.io/github/release/nixel2007/entity.svg?style=flat-square)](https://github.com/nixel2007/entity/releases)
[![GitHub license](https://img.shields.io/github/license/nixel2007/entity.svg?style=flat-square)](https://github.com/nixel2007/entity/blob/develop/LICENSE.md)
[![Статус Порога Качества](https://sonar.openbsl.ru/api/project_badges/measure?project=entity&metric=alert_status)](https://sonar.openbsl.ru/dashboard?id=entity)
[![Рейтинг Сопровождаемости](https://sonar.openbsl.ru/api/project_badges/measure?project=entity&metric=sqale_rating)](https://sonar.openbsl.ru/dashboard?id=entity)

Библиотека `Entity` предназначена для работы с данными БД как с простыми OneScript объектами. Является реализацией концепции ORM и шаблонов [`DataMapper`](https://martinfowler.com/eaaCatalog/dataMapper.html) и [`ActiveRecord`](https://www.martinfowler.com/eaaCatalog/activeRecord.html) в OneScript. Вдохновение черпается из [Java Persistence API](https://ru.wikipedia.org/wiki/Java_Persistence_API) и [TypeORM](https://github.com/typeorm/typeorm).

Возможности:

* описание таблиц БД в виде специальным образом аннотированных OneScript классов;
* сохранение объектов OneScript в связанных таблицах БД;
* поиск по таблицам с результатом в виде коллекции заполненных данными объектов OneScript;
* абстрактный программный интерфейс (API), не зависящий от используемой СУБД;
* референсная реализация полнофункционального коннектора к SQLite и PostgreSQL, а так же упрощенного коннектора к файлам JSON.

Описание публичного интерфейса - каталог [docs](docs).

## Оглавление

* <a href="#header">entity - OneScript Persistence API</a>
  * <a href="#entity-example">Пример класса-сущности</a>
  * <a href="#entity-create">Создание и сохранение сущностей</a>
  * <a href="#entity-read">Чтение и поиск объектов</a>
    * <a href="#entity-complex-find">Поиск сущностей со сложными отборами</a>
  * <a href="#entity-delete">Удаление сущностей</a>
  * <a href="#entity-active-record">Активная запись</a>
  * <a href="#entity-repository">Работа через ХранилищеСущностей</a>
  * <a href="#transactions">Работа с транзакциями</a>
  * <a href="#annotations">Система аннотаций для сущностей</a>
    * <a href="#annotation-entity">Сущность</a>
    * <a href="#annotation-id">Идентификатор</a>
    * <a href="#annotation-generated">ГенерируемоеЗначение</a>
    * <a href="#annotation-column">Колонка</a>
    * <a href="#annotation-secondary-table">ПодчиненнаяТаблица</a>
  * <a href="#library-structure">Структура библиотеки</a>
    * <a href="#library-structure-entity-manager">МенеджерСущностей</a>
    * <a href="#library-structure-entity-repository">ХранилищеСущностей</a>
    * <a href="#library-structure-connectors">Коннекторы (АбстрактныйКоннектор)</a>
    * <a href="#library-structure-data-model">МодельДанных</a>
    * <a href="#library-structure-model-object">ОбъектМодели</a>
    * <a href="#library-structure-connector-sqlite">КоннекторSQLite</a>
    * <a href="#library-structure-connector-postgresql">КоннекторPostgreSQL</a>
    * <a href="#library-structure-connector-json">КоннекторJSON</a>
    * <a href="#library-structure-connector-inmemory">КоннекторInMemory</a>
  * <a href="#versioning-strategy">Версионирование и обратная совместимость</a>

<a id="entity-example" />

## Пример класса-сущности

Сущность - это обычный класс OneScript, размеченный служебными аннотациями. Обязательными аннотациями являются `&Сущность` и `&Идентификатор`.

Библиотека `entity` считывает состав аннотаций класса, строит модель данных и инициализирует таблицы базы данных для работы с объектами данного класса.

Ограничения:

* класс-сущность должен иметь конструктор по умолчанию, либо конструктор без параметров, либо конструктор со значениями всех параметров по умолчанию.

```bsl
// file: СтраныМира.os

// Данный класс содержит данные о странах мира.

&Идентификатор                        // Колонка для хранения ID сущности
Перем Код Экспорт;                    // Колонка по умолчанию имеет строковый тип

Перем Наименование Экспорт;           // Колонка `Наименование` будет создана в таблице, т.к. поле экспортное.

&Сущность                             // Объект с типом "СтраныМира" будет представлен в СУБД как таблица "СтраныМира"
Процедура ПриСозданииОбъекта()

КонецПроцедуры
```

```bsl
// file: Документ.os

&Идентификатор
&ГенерируемоеЗначение                      // Заполняется автоматически при сохранении сущности
&Колонка(Тип = "Целое")                    // Хранит целочисленные значения
Перем Идентификатор Экспорт;               // Имя колонки в базе - `Идентификатор`

&Колонка
Перем Номер Экспорт;                       // Колонка `Номер` будет создана в таблице, т.к. поле экспортное

&Колонка
Перем Серия Экспорт;                       // Колонка `Номер` будет создана в таблице, т.к. поле экспортное

&Сущность(ИмяТаблицы = "Документы")
Процедура ПриСозданииОбъекта()             // Объект с типом "Документ" будет представлен в СУБД как таблица "Документы"

КонецПроцедуры
```

```bsl
// file: ФизическоеЛицо.os

// Данный класс содержит информацию о физических лицах.

&Идентификатор                             // Колонка для хранения ID сущности
&ГенерируемоеЗначение                      // Заполняется автоматически при сохранении сущности
&Колонка(Тип = "Целое")                    // Хранит целочисленные значения
Перем Идентификатор Экспорт;               // Имя колонки в базе - `Идентификатор`

Перем Имя Экспорт;                         // Колонка `Имя` будет создана в таблице, т.к. поле экспортное.
&Колонка(Имя = "Отчество")                 // Поле `ВтороеИмя` в таблице будет представлено колонкой `Отчество`.
Перем ВтороеИмя Экспорт;

&Колонка(Тип = "Дата")                     // Колонка `ДатаРождения` хранит значения в формате дата-без-времени
Перем ДатаРождения Экспорт;

&Колонка(Тип = "Ссылка", ТипСсылки = "СтраныМира")
Перем Гражданство Экспорт;                 // Данная колонка будет хранить ссылку на класс `СтраныМира`

&ПодчиненнаяТаблица(Тип = "Массив", ТипЭлемента = "Документы", КаскадноеЧтение = Истина)
Перем Документы Экспорт;                   // Данное поле будет хранить массив ссылок на класс `Документ`.
                                           // Для хранения массива будет создана отдельная таблица.
                                           // Взведенный флаг "КаскадноеЧтение" сигнализирует о необходимости
                                           // инициализировать сущности в массиве при чтении объекта из СУБД.

&Сущность(ИмяТаблицы = "ФизическиеЛица")   // Объект с типом `ФизическоеЛицо` (по имени файла) будет представлен в СУБД в виде таблицы `ФизическиеЛица`
Процедура ПриСозданииОбъекта()

КонецПроцедуры
```

<a id="entity-create" />

## Создание и сохранение сущностей

```bsl
// Создание менеджера сущностей. Коннектором к базе выступает референсная реализация КоннекторSQLite.
// В качестве БД используется "база в оперативной памяти".
МенеджерСущностей = Новый МенеджерСущностей(Тип("КоннекторSQLite"), "FullUri=file::memory:?cache=shared");

// Создание или обновление таблиц в БД.
МенеджерСущностей.ДобавитьКлассВМодель(Тип("СтраныМира"));
МенеджерСущностей.ДобавитьКлассВМодель(Тип("Документ"));
МенеджерСущностей.ДобавитьКлассВМодель(Тип("ФизическоеЛицо"));

// После заполнения модели менеджер необходимо проинициализировать.
МенеджерСущностей.Инициализировать();

// Работа с обычными объектом OneScript.
СохраняемоеФизЛицо = Новый ФизическоеЛицо;
СохраняемоеФизЛицо.Имя = "Иван";
СохраняемоеФизЛицо.ВтороеИмя = "Иванович";
СохраняемоеФизЛицо.ДатаРождения = Дата(1990, 01, 01);

СтранаМира = Новый СтраныМира;
СтранаМира.Код = "643";
СтранаМира.Наименование = "Российская Федерация";

Паспорт = Новый Документ;
Паспорт.Номер = "11 11";
Паспорт.Серия = "111000";

// Присваиваем колонке с типом "Ссылка" конкретный объект с типом "СтраныМира"
СохраняемоеФизЛицо.Гражданство = СтранаМира;

// Инициализируем массив для хранения документов.
// Это можно сделать и в методе ПриСозданииОбъекта в классе ФизическоеЛицо.os
СохраняемоеФизЛицо.Документы = Новый Массив;
// Добавляем новый документ
СохраняемоеФизЛицо.Документы.Добавить(Паспорт);

// Сохранение объектов в БД
// Сначала сохраняются подчиненные сущности, потом высокоуровневые
МенеджерСущностей.Сохранить(СтранаМира);
МенеджерСущностей.Сохранить(Паспорт);
МенеджерСущностей.Сохранить(СохраняемоеФизЛицо);

// После сохранения СохраняемоеФизЛицо.Идентификатор содержит автосгенерированный идентификатор.
// Колонка "Гражданство" в СУБД будет хранить идентификатор объекта СтранаМира - значение "643".
// Для хранения документов будет создана отдельная таблица, в которой будут сохранены
// значения массива с привязкой к физическому лицу.
```

<a id="entity-read" />

## Чтение и поиск объектов

Для поиска сущностей существуют методы `Получить()` и `ПолучитьОдно()`.

Метод `Получить()` возвращает массив найденных сущностей.

Метод `ПолучитьОдно()` возвращает одну (первую попавшуюся) сущность или `Неопределено`, если найти сущность не удалось.

Оба метода в качестве второго параметра могут принимать в себя условия отбора в следующих видах:

* `Неопределено` (параметр не заполнен) - поиск без отборов;
* `Соответствие` - пары ИмяПоля-ЗначениеПоля, используемые как отбор по "равно";
* `ЭлементОтбора` - объект типа "ЭлементОтбора", позволяющий использовать более сложные условия, например, с видом сравнения "БольшеИлиРавно";
* `Массив` - массив с элементами типа "ЭлементОтбора", позволяющий использовать сложные условия отбора, соединяемые через логическое `И`.

### Поиск сущностей с простыми отборами

```bsl
// Для поиска нескольких сущностей, удовлетворяющих условию, можно использовать метод Получить()
// При вызове метода без параметров будут полученные все сущности указанного типа.
// В массиве содержатся объекты типа "ФизическоеЛицо" с заполненными значениями полей.
// Поле "Гражданство" заполнится готовым объектом с типом "СтраныМира".
// Т.к. над полем "Документы" взведен флаг "КаскадноеЧтение", то данное поле
// заполнится массивом с готовыми объектами типа "Документ".
// В обратном случае в массиве содержались бы идентификаторы (ключи) сущностей "Документ".
НайденныеФизЛица = МенеджерСущностей.Получить(Тип("ФизическоеЛицо"));

// В метод Получить() можно передать отбор в виде соответствия
Отбор = Новый Соответствие;
Отбор.Вставить("Имя", "Иван");
Отбор.Вставить("ВтороеИмя", "Иванович");

// В результирующем массиве окажутся все "Иваны Ивановичи", сохраненные в БД.
НайденныеИваныИванычи = МенеджерСущностей.Получить(Тип("ФизическоеЛицо"), Отбор);

// Допустим в БД сохранено физ. лицо с идентификатором, равным 123.
// Для получения одной (первой попавшейся) сущности можно использовать метод ПолучитьОдно()
СохраненноеФизЛицо = МенеджерСущностей.ПолучитьОдно(Тип("ФизическоеЛицо"));

// В метод можно передать отбор в виде соответствия, аналогично методу Получить()
СохраненноеФизЛицо = МенеджерСущностей.ПолучитьОдно(Тип("ФизическоеЛицо"), Отбор);

// Если вызвать метод "ПолучитьОдно" с параметром не-соответствием, то будет осуществлен поиск по идентификатору сущности.
Идентификатор = 123;
СохраненноеФизЛицо = МенеджерСущностей.ПолучитьОдно(Тип("ФизическоеЛицо"), Идентификатор);
```

<a id="entity-complex-find" />

### Поиск сущностей со сложными отборами

```bsl
// Найдем всех физических лиц, у которых дата рождения больше, чем 01.01.1990.
ЭлементОтбора = Новый ЭлементОтбора("ДатаРождения", ВидСравнения.БольшеИлиРавно, Дата(1990, 1, 1));
НайденныеФизЛица = МенеджерСущностей.Получить(Тип("ФизическоеЛицо"), ЭлементОтбора);

// Найдем всех физических лиц, рожденных в 90-ые.
МассивОтборов = Новый Массив;
МассивОтборов.Добавить(Новый ЭлементОтбора("ДатаРождения", ВидСравнения.БольшеИлиРавно, Дата(1990, 1, 1)));
МассивОтборов.Добавить(Новый ЭлементОтбора("ДатаРождения", ВидСравнения.Меньше, Дата(2000, 1, 1)));

ДетиДевяностых = МенеджерСущностей.Получить(Тип("ФизическоеЛицо"), МассивОтборов);
```

<a id="entity-delete" />

## Удаление сущностей

```bsl
// Допустим имеется сущность, которую надо удалить.

МенеджерСущностей.Удалить(СущностьФизическоеЛицо);

// После выполнения метода в БД не останется строки с идентификатором, равным идентификатору сущности
```

<a id="entity-repository" />

## Работа через ХранилищеСущностей

Для упрощения взаимодействия с библиотекой помимо МенеджераСущностей, подразумевающего постоянную передачу *типа сущности*, осуществлять операции над сущностями можно через ХранилищеСущностей.  
Хранилище сущностей предоставляет тот же базовый интерфейс, что и МенеджерСущностей, но не требует передачи типа сущности как параметра.

```bsl
// Получение хранилища сущностей
ХранилищеФизЛиц = МенеджерСущностей.ПолучитьХранилищеСущностей(Тип("ФизическоеЛицо"));

// Поиск сущностей
Идентификатор = 1;
ФизЛицо = ХранилищеФизЛиц.ПолучитьОдно(Идентификатор);

ФизЛицо.Имя = "Петр";

ХранилищеФизЛиц.Сохранить(ФизЛицо);
```

<a id="entity-active-record" />

## Активная запись

Для упрощения работы с сущностями помимо сохранения и удаления сущностей через МенеджерСущностей или ХранилищеСущностей сами объекты сущностей декорируются дополнительными методами `Сохранить`, `Прочитать` и `Удалить`. Все типы сущностей, полученные из Менеджера или Хранилища сущностей с помощью методов `Получить` или `ПолучитьОдно` автоматически декорируются. Для создания нового экземпляра сущности, имеющего дополнительные методы, можно воспользоваться методом `СоздатьЭлемент` у Менеджера или Хранилища сущностей.

```bsl
// Получение хранилища сущностей.
ХранилищеФизЛиц = МенеджерСущностей.ПолучитьХранилищеСущностей(Тип("ФизическоеЛицо"));

// Создание сущности, обладающей методами "активной записи".
ФизЛицо = ХранилищеФизЛиц.СоздатьЭлемент();
ФизЛицо.Идентификатор = 1;

// Чтение данных сущности по текущему идентификатору.
// Все поля сущности проинициализируются значениями из базы.
ФизЛицо.Прочитать();

// Изменение данных и сохранение через "активную запись"
ФизЛицо.Имя = "Петр";
ФизЛицо.Сохранить();

// Сущности, полученные из Хранилища сущностей сразу становятся "активной записью"
Идентификатор = 2;
ВтороеФизЛицо = ХранилищеФизЛиц.ПолучитьОдно(Идентификатор);

// И могут быть удалены, через методы "активной записи"
ВтороеФизЛицо.Удалить();
```

<a id="transactions" />

### Работа с транзакциями

Методы по работе с транзакциями есть как в Менеджере сущностей, так и в Хранилище сущностей.

Транзакционность поддерживается в рамках экземпляра менеджера сущностей или хранилища сущностей. При необходимости работы с транзакциями с несколькими типами сущностей следует использовать методы работы с транзакциями в Менеджере сущностей и модифицировать сущности через него же.

```bsl
МенеджерСущностей.НачатьТранзакцию();

// Объекты ФизическоеЛицо и СтранаМира из примеров выше:
МенеджерСущностей.Сохранить(СтранаМира);
МенеджерСущностей.Сохранить(СохраняемоеФизЛицо);

МенеджерСущностей.ЗафиксироватьТранзакцию();
```

<a id="annotations" />

## Система аннотаций для сущностей

Для связями между классом на OneScript и таблицей в БД используется система аннотаций. Часть аннотаций обязательная к применению. Все параметры аннотаций необязательные.

При анализе типа сущности менеджер сущностей формирует специальные объекты модели, передаваемые конкретным реализациям коннекторов. Коннекторы могут рассчитывать на наличие всех описанных параметров аннотаций в объекте модели.

<a id="annotation-entity" />

### Сущность

> Применение: обязательно

Каждый класс, подключаемый к менеджеру сущностей должен иметь аннотацию `Сущность`, расположенную над любым методом класса.

При отсутствии у класса методов рекомендуется навешивать аннотацию над методом `ПриСозданииОбъекта()`.

Аннотация `Сущность` имеет следующие параметры:

* `ИмяТаблицы` - Строка - Имя таблицы, используемой коннектором к СУБД при работе с сущностью. Значение по умолчанию - строковое представление имени типа сценария. При подключении сценариев стандартным загрузчиком библиотек совпадает с именем файла.

<a id="annotation-id" />

### Идентификатор

> Применение: обязательно

Каждый класс, подключаемый к менеджеру сущностей должен иметь поле для хранения идентификатора объекта в СУБД - первичного ключа. Для формирования автоинкрементного первичного ключа можно воспользоваться дополнительной аннотацией `ГенерируемоеЗначение`.

Аннотация `Идентификатор` не имеет параметров.

<a id="annotation-generated" />

### ГенерируемоеЗначение

> Применение: необязательно

Для части полей допустимо высчитывать значение колонки при вставке записи в таблицу. Например, для первичных числовых ключей обычно не требуется явное управление назначаемыми идентификаторами.

Референсная реализация коннектора на базе SQLite поддерживает единственный тип генератора значений - `AUTOINCREMENT`.

> Планируется расширение аннотации указанием параметров генератора.

Аннотация `ГенерируемоеЗначение` не имеет параметров.

<a id="annotation-column" />

### Колонка

> Применение: необязательно

Все **экспортные** поля класса (за исключением полей, помеченных аннотаций `ПодчиненнаяТаблица`) преобразуются в колонки таблицы в СУБД. Аннотация `Колонка` позволяет тонко настроить параметры колонки таблицы.

Аннотация `Колонка` имеет следующие параметры:

* `Имя` - Строка - Имя колонки, используемой коннектором к СУБД при работе с сущностью. Значение по умолчанию - имя свойства.
* `Тип` - ТипыКолонок - Тип колонки, используемой для хранения идентификатора. Значение по умолчанию - `ТипыКолонок.Строка`. Доступные типы колонок:
  * Целое
  * Дробное
  * Булево
  * Строка
  * Дата
  * Время
  * ДатаВремя
  * Ссылка
  * ДвоичныеДанные
* `ТипСсылки` - Строка - Имя зарегистрированного в модели типа, в который преобразуется значение из колонки. Имеет смысл только в паре с параметром `Тип`, равным `Ссылка`. Допустимо указывать примитивные типы из перечисления `ТипыКолонок` и типы сущностей (например, `"ФизическоеЛицо"`)

<a id="annotation-secondary-table" />

### ПодчиненнаяТаблица

> Применение: необязательно

Аннотация `ПодчиненнаяТаблица` используется для хранения коллекций - массивов и структур.

Аннотация `ПодчиненнаяТаблица` имеет следующие параметры:

* `ИмяТаблицы` - Строка - Имя таблицы, используемой коннектором к СУБД при работе с сущностью. Значение по умолчанию - строка вида `ИмяТаблицыСущности_ИмяСвойства`.
* `Тип` - ТипыПодчиненныхТаблиц - Тип колонки, используемой для хранения идентификатора. Доступные типы подчиненных таблиц:
  * Массив
  * Структура
* `ТипЭлемента` - Строка - Имя зарегистрированного в модели типа, в который преобразуется значение из колонки. Допустимо указывать примитивные типы из перечисления `ТипыКолонок` и типы сущностей (например, `"ФизическоеЛицо"`).
* `КаскадноеЧтение` - Булево - Флаг, отвечающий за инициализацию сущностей в подчиненной таблице (если `ТипЭлемента` является ссылочным типом).

<a id="library-structure" />

## Структура библиотеки

Описание публичного интерфейса - каталог [docs](docs).

<a id="library-structure-entity-manager" />

### МенеджерСущностей

МенеджерСущностей предоставляет публичный интерфейс по чтению, сохранению, удалению данных. МенеджерСущностей инициализируется конкретным типом *коннектора* к используемой базе данных. Все операции по изменению данных МенеджерСущностей делегирует Коннектору. В зоне ответственности МенеджераСущностей находятся:

* Создание и наполнение МоделиДанных
* Трансляция запросов от прикладной логики к коннекторам
* Конструирование найденных сущностей по данным, возвращаемым коннекторами

<a id="library-structure-entity-repository" />

### ХранилищеСущностей

ХранилищеСущностей предоставляет тот же интерфейс по работе с сущностями и транзакциями, но с глобальной привязкой к конкретному типу сущности. Для получения ХранилищаСущностей служит метод `МенеджерСущностей::ПолучитьХранилищеСущностей`.

В отличие от МенеджераСущностей, ХранилищеСущностей не требует передачи в методы параметра "ТипСущности".

Хранилища сущностей и пулы сущностей совпадают в рамках одного типа сущности, типа коннектора и строки соединения. Другими словами, два менеджера сущности, инициализированные одним и тем же коннектором и строкой соединения, вернут одинаковые хранилища сущностей одного типа.

<a id="library-structure-connectors" />

### Коннекторы (АбстрактныйКоннектор)

Коннектор содержит в себе логику по работе с конкретной СУБД. Например, `КоннекторSQLite` служит для оперирования СУБД SQLite. В зоне ответственности коннектора находятся:

* подключение к СУБД
* работа с транзакциями
* инициализация таблиц базы данных;
* CRUD-операции над таблицами, в которых хранятся сущности (создание-получение-обновление-удаление);
* преобразование типов по данным ОбъектаМодели в типы колонок СУБД.

Ко всем коннекторам предъявляются определенные требования:

* каждый коннектор **обязан** реализовывать интерфейс, представленный в классе [`АбстрактныйКоннектор`](https://github.com/nixel2007/entity/blob/develop/src/%D0%9A%D0%BB%D0%B0%D1%81%D1%81%D1%8B/%D0%90%D0%B1%D1%81%D1%82%D1%80%D0%B0%D0%BA%D1%82%D0%BD%D1%8B%D0%B9%D0%9A%D0%BE%D0%BD%D0%BD%D0%B5%D0%BA%D1%82%D0%BE%D1%80.os);
* коннектор **может** писать предупреждающие сообщения или выдавать исключения на методах, которые он не поддерживает или поддерживает не полностью.

Например, `КоннекторJSON` не умеет работать с транзакциями, однако, он имеет соответствующие методы, выводящие диагностические сообщения при их вызове.

> Важно!

Каждое ХранилищеСущностей и МенеджерСущностей хранят в себе отдельные экземпляры Коннекторов. Тип, строка соединения и параметры коннектора определяются при создании МенеджераСущностей.

<a id="library-structure-data-model" />

### МодельДанных

Модель данных хранит в себе список всех зарегистрированных классов-сущности в виде ОбъектовМодели

<a id="library-structure-model-object" />

### ОбъектМодели

ОбъектМодели хранит детальную мета-информацию о классе сущности, его полях и данных всех аннотаций. Из ОбъектаМодели можно получить:

* тип сущности;
* имя таблицы для хранения сущности;
* список всех колонок, с информацией о:
  * имени поля класса;
  * имени колонки в БД;
  * типе колонки в БД;
  * типе элемента (в случае ссылочного типа колонки);
  * значения флага "Идентификатор";
  * значения флага "ГенерируемоеЗначение";
* список подчиненных таблиц с информацией о:
  * имени поля класса
  * имени таблицы в БД
  * типе подчиненной таблицы
  * типе элемента
* ссылку на данные колонки-идентификатора.

Помимо мета-информации ОбъектМодели позволяет получать значения колонок таблицы на основании имен полей сущности (и наоборот), вычислять значение идентификатора сущности, выполнять приведение типов и установку значений полей сущности.

<a id="library-structure-connector-sqlite" />

### КоннекторSQLite

В состав библиотеки входит референсная реализация интерфейса коннектора в виде коннектора к СУБД SQLite. Реализация базируется на библиотеке [sql](https://github.com/oscript-library/sql), есть поддержка работы в OneScript.Web.

Коннектор SQLite поддерживает все CRUD-операции над сущностями, простой и сложный поиск, работу с транзакциями.

> Внимание!

При использовании in-memory базы данных в моделях больше, чем с одним типом сущности, строка соединения должна выглядеть так: `"FullUri=file::memory:?cache=shared"`

<a id="library-structure-connector-postgresql" />

### КоннекторPostgreSQL

В состав библиотеки входит референсная реализация интерфейса коннектора в виде коннектора к СУБД PostgreSQL. Реализация базируется на библиотеке [sql](https://github.com/oscript-library/sql), есть поддержка работы в OneScript.Web.

Коннектор PostgreSQL поддерживает все CRUD-операции над сущностями, простой и сложный поиск, работу с транзакциями.

<a id="library-structure-connector-json" />

### КоннекторJSON

В состав библиотеки входит референсная реализация интерфейса коннектора в виде упрощенного коннектора к набору файлов JSON. Каждая таблица хранится в отдельном файле в формате JSON в виде пар Ключ-Значение, где ключом выступает идентификатор сущности, а значением - сериализованная в JSON-объект сущность.

В качестве строки соединения указывается путь к каталогу, в котором будут сохранены файлы.

Коннектор SQLite поддерживает все CRUD-операции над сущностями, простой и сложный поиск, но не поддерживает работу с транзакциями. При вызове операций по работе с транзакциями будут выданы исключения.

Все операциями по записи и удалению сущностей одного типа проводятся **синхронно**, блокируя файл таблицы целиком. Для контроля над синхронным доступом используется библиотека [semaphore](https://github.com/nixel2007/semaphore).

<a id="library-structure-connector-inmemory" />

### КоннекторInMemory

В состав библиотеки входит референсная реализация интерфейса коннектора в виде упрощенного коннектора к виртуальной базе данных в памяти. База данных состоит из соответствия, где ключ - имя таблицы модели данных, значение таблицы.

В качестве строки соединения произвольная строка, которая будет являться разделителем данных.

Коннектор поддерживает все CRUD-операции над сущностями, простой и сложный поиск, но не поддерживает работу с транзакциями. При вызове операций по работе с транзакциями будут выданы исключения.

<a id="versioning-strategy" />

## Версионирование и обратная совместимость

Библиотека `entity` в целом следует концепции [семантического версионирования](https://semver.org/) со следующими изменениями в правилах нумерации версий:

* первая цифра версии - Major.Entity - версия API Менеджера сущностей;
* вторая цифра версии - Major.Connector - версия API Коннекторов;
* третья цифра версии - Minor - новая функциональность в рамках мажорных версий;
* четвертая цифра версии - Patch - исправление ошибок.

Таким образом:

* прикладное ПО может быть уверено в сохранении обратной совместимости в рамках первой цифры версии;
* коннекторы к СУБД могут быть уверены в сохранении обратной совместимости и требований по реализации API в рамках второй цифры версии, невзирая на значение первой цифры.

Под контроль и обязательство соблюдения обратной совместимости попадают:

* для Major.Entity:
  * все публичные непомеченные как "нестабильные" (`@unstable`) или "для служебного использования" (`@internal`) методы классов:
    * [`МенеджерСущностей`](src/Классы/МенеджерСущностей.os),
    * [`ХранилищеСущностей`](src/Классы/ХранилищеСущностей.os),
    * [`МодельДанных`](src/Классы/МодельДанных.os),
    * [`ОбъектМодели`](src/Классы/ОбъектМодели.os),
    * [`ЭлементОтбора`](src/Классы/ЭлементОтбора.os);
  * значения модулей-перечислений:
    * [`ТипыКолонок`](src/Модули/ТипыКолонок.os),
    * [`ТипыПодчиненныхТаблиц`](src/Модули/ТипыПодчиненныхТаблиц.os),
    * [`ВидСравнения`](src/Модули/ВидСравнения.os);
  * состав и параметры аннотаций сущностей;
  * методы ["активной записи"](docs/АктивнаяЗапись.md) сущности;
* для Major.Connector:
  * все публичные методы класса [`АбстрактныйКоннектор`](src/Классы/АбстрактныйКоннектор.os) и их сигнатуры;
  * все публичные непомеченные как "нестабильные" (`@unstable`) методы классов:
    * [`МодельДанных`](src/Классы/МодельДанных.os),
    * [`ОбъектМодели`](src/Классы/ОбъектМодели.os),
    * [`ЭлементОтбора`](src/Классы/ЭлементОтбора.os);
  * значения модулей-перечислений:
    * [`ТипыКолонок`](src/Модули/ТипыКолонок.os),
    * [`ТипыПодчиненныхТаблиц`](src/Модули/ТипыПодчиненныхТаблиц.os),
    * [`ВидСравнения`](src/Модули/ВидСравнения.os).

> To be continued...
