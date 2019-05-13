#Использовать asserts
#Использовать logos
#Использовать reflector
#Использовать semaphore
#Использовать strings

Перем КонструкторКоннектора;
Перем Соединение;
Перем КартаТипов;

Перем Лог;

// Конструктор объекта КоннекторSQLite.
//
Процедура ПриСозданииОбъекта()
	КонструкторКоннектора = ПолучитьКонструкторКоннектора();
	Соединение = КонструкторКоннектора.НовыйСоединение();
	КартаТипов = СоответствиеТиповМоделиИТиповКолонок();
	
	Лог = Логирование.ПолучитьЛог("oscript.lib.entity.connector.sqlite");
КонецПроцедуры

// Открыть соединение с БД.
//
// Параметры:
//   СтрокаСоединения - Строка - Строка соединения с БД.
//   ПараметрыКоннектора - Массив - Дополнительные параметры инициализации коннектора.
//
Процедура Открыть(СтрокаСоединения, ПараметрыКоннектора) Экспорт
	КонструкторКоннектора.Открыть(Соединение, СтрокаСоединения);
КонецПроцедуры

// Закрыть соединение с БД.
//
Процедура Закрыть() Экспорт
	КонструкторКоннектора.Закрыть(Соединение);
КонецПроцедуры

// Получить статус соединения с БД.
//
//  Возвращаемое значение:
//   Булево - Состояние соединения. Истина, если соединение установлено и готово к использованию.
//       В обратном случае - Ложь.
//
Функция Открыт() Экспорт
	Возврат Соединение.Открыто;
КонецФункции

// Начинает новую транзакцию в БД.
//
Процедура НачатьТранзакцию() Экспорт
	Запрос = КонструкторКоннектора.НовыйЗапрос(Соединение);
	Запрос.Текст = "BEGIN TRANSACTION;";
	Запрос.ВыполнитьКоманду();
КонецПроцедуры

// Фиксирует открытую транзакцию в БД.
//
Процедура ЗафиксироватьТранзакцию() Экспорт
	Запрос = КонструкторКоннектора.НовыйЗапрос(Соединение);
	Запрос.Текст = "COMMIT TRANSACTION;";
	Запрос.ВыполнитьКоманду();
КонецПроцедуры

// Отменяет открытую транзакцию в БД.
//
Процедура ОтменитьТранзакцию() Экспорт
	Запрос = КонструкторКоннектора.НовыйЗапрос(Соединение);
	Запрос.Текст = "ROLLBACK TRANSACTION;";
	Запрос.ВыполнитьКоманду();
КонецПроцедуры

// Создает таблицу в БД по данным модели.
//
// Параметры:
//   ОбъектМодели - ОбъектМодели - Объект, содержащий описание класса-сущности и настроек таблицы БД.
//
Процедура ИнициализироватьТаблицу(ОбъектМодели) Экспорт
	
	ИмяТаблицы = ОбъектМодели.ИмяТаблицы();
	
	ШаблонСозданияТаблицы = "CREATE TABLE IF NOT EXISTS %1 (
		|%2
		|);";
	
	ТекстЗапроса = ШаблонСозданияТаблицы;
	
	КолонкиТаблицы = ОбъектМодели.Колонки();
	Идентификатор = ОбъектМодели.Идентификатор();
	СтрокаОпределенийКолонок = "";
	СтрокаВнешнихКлючей = "";
	Для Каждого Колонка Из КолонкиТаблицы Цикл
				
		ТипКолонкиСУБД = ПолучитьТипКолонкиСУБД(ОбъектМодели, Колонка);
		ОписаниеВнешнегоКлюча = ПолучитьОписаниеВнешнегоКлюча(ОбъектМодели, Колонка);
		
		// Формирование строки-колонки
		СтрокаКолонка = Символы.Таб + Колонка.ИмяКолонки;
		
		СтрокаКолонка = СтрокаКолонка + " " + ТипКолонкиСУБД;
		Если Колонка.ИмяПоля = Идентификатор.ИмяПоля Тогда
			СтрокаКолонка = СтрокаКолонка + " PRIMARY KEY";
		КонецЕсли;
		Если Колонка.ГенерируемоеЗначение Тогда
			СтрокаКолонка = СтрокаКолонка + " AUTOINCREMENT";
		КонецЕсли;
		СтрокаКолонка = СтрокаКолонка + "," + Символы.ПС;
		
		СтрокаОпределенийКолонок = СтрокаОпределенийКолонок + СтрокаКолонка;
		Если ЗначениеЗаполнено(ОписаниеВнешнегоКлюча) Тогда
			СтрокаВнешнихКлючей = СтрокаВнешнихКлючей + ОписаниеВнешнегоКлюча;
		КонецЕсли;
	КонецЦикла;
	
	СтрокаОпределенийКолонок = СтрокаОпределенийКолонок + СтрокаВнешнихКлючей;
	
	СтроковыеФункции.УдалитьПоследнийСимволВСтроке(СтрокаОпределенийКолонок, 2);
	
	ТекстЗапроса = СтрШаблон(ТекстЗапроса, ИмяТаблицы, СтрокаОпределенийКолонок);
	Лог.Отладка("Инициализация таблицы %1:%2%3", ИмяТаблицы, Символы.ПС, ТекстЗапроса);
	
	Запрос = КонструкторКоннектора.НовыйЗапрос(Соединение);
	Запрос.Текст = ТекстЗапроса;
	
	Запрос.ВыполнитьКоманду();
	
КонецПроцедуры

// Сохраняет сущность в БД.
//
// Параметры:
//   ОбъектМодели - ОбъектМодели - Объект, содержащий описание класса-сущности и настроек таблицы БД.
//   Сущность - Произвольный - Объект (экземпляр класса, зарегистрированного в модели) для сохранения в БД.
//
Процедура Сохранить(ОбъектМодели, Сущность) Экспорт
	
	ИмяТаблицы = ОбъектМодели.ИмяТаблицы();
	КолонкиТаблицы = ОбъектМодели.Колонки();
	
	Запрос = КонструкторКоннектора.НовыйЗапрос(Соединение);
	
	ИменаКолонок = "";
	ЗначенияКолонок = "";
	
	Если КолонкиТаблицы.Количество() = 1 И ОбъектМодели.Идентификатор().ГенерируемоеЗначение Тогда
		ИменаКолонок = Символы.Таб + ОбъектМодели.Идентификатор().ИмяКолонки;
		ЗначенияКолонок = Символы.Таб + "null";
	Иначе
		Для Каждого ДанныеОКолонке Из КолонкиТаблицы Цикл
			ЗначениеПараметра = ОбъектМодели.ПолучитьПриведенноеЗначениеПоля(Сущность, ДанныеОКолонке.ИмяПоля);
			
			Если ДанныеОКолонке.ГенерируемоеЗначение И НЕ ЗначениеЗаполнено(ЗначениеПараметра) Тогда
				// TODO: Поддержка чего-то кроме автоинкремента
				Продолжить;
			КонецЕсли;
			ИменаКолонок = ИменаКолонок + Символы.Таб + ДанныеОКолонке.ИмяКолонки + "," + Символы.ПС;
			ЗначенияКолонок = ЗначенияКолонок + Символы.Таб + "@" + ДанныеОКолонке.ИмяКолонки + "," + Символы.ПС;
			
			Запрос.УстановитьПараметр(ДанныеОКолонке.ИмяКолонки, ЗначениеПараметра);
		КонецЦикла;
		
		СтроковыеФункции.УдалитьПоследнийСимволВСтроке(ИменаКолонок, 2);
		СтроковыеФункции.УдалитьПоследнийСимволВСтроке(ЗначенияКолонок, 2);
	КонецЕсли;
	
	ТекстЗапроса = "INSERT OR REPLACE INTO %1 (
		|%2
		|) VALUES (
		|%3
		|);";
	
	ТекстЗапроса = СтрШаблон(ТекстЗапроса, ИмяТаблицы, ИменаКолонок, ЗначенияКолонок);
	Лог.Отладка("Сохранение сущности с типом %1:%2%3", ОбъектМодели.ТипСущности(), Символы.ПС, ТекстЗапроса);
	
	Семафор = Семафоры.Получить(Строка(ОбъектМодели.ТипСущности()));
	Семафор.Захватить();
	Запрос.Текст = ТекстЗапроса;
	Запрос.ВыполнитьКоманду();
	
	Если ОбъектМодели.Идентификатор().ГенерируемоеЗначение Тогда
		ИДПоследнейДобавленнойЗаписи = КонструкторКоннектора.ИДПоследнейДобавленнойЗаписи(Соединение, Запрос);
		ОбъектМодели.УстановитьЗначениеКолонкиВПоле(
			Сущность,
			ОбъектМодели.Идентификатор().ИмяКолонки,
			ИДПоследнейДобавленнойЗаписи
		);
	КонецЕсли;
	
	Семафор.Освободить();
	
	// TODO: Для полей с автоинкрементом - получить значения из базы.
	// по факту - просто переинициализировать класс значениями полей из СУБД.
	// ЗаполнитьСущность(Сущность, ОбъектМодели);
	
КонецПроцедуры

// Удаляет сущность из таблицы БД.
//
// Параметры:
//   ОбъектМодели - ОбъектМодели - Объект, содержащий описание класса-сущности и настроек таблицы БД.
//   Сущность - Произвольный - Объект (экземпляр класса, зарегистрированного в модели) для удаления из БД.
//
Процедура Удалить(ОбъектМодели, Сущность) Экспорт
	
	ИмяТаблицы = ОбъектМодели.ИмяТаблицы();
	
	ТекстЗапроса = "DELETE FROM %1
		|WHERE %2 = @Идентификатор;";
	
	ТекстЗапроса = СтрШаблон(ТекстЗапроса, ИмяТаблицы, ОбъектМодели.Идентификатор().ИмяКолонки);
	Лог.Отладка(
		"Удаление сущности с типом %1 и идентификатором %2:%3%4",
		ОбъектМодели.ТипСущности(),
		ОбъектМодели.ПолучитьЗначениеИдентификатора(Сущность),
		Символы.ПС,
		ТекстЗапроса
	);
	
	Запрос = КонструкторКоннектора.НовыйЗапрос(Соединение);
	Запрос.Текст = ТекстЗапроса;
	Запрос.УстановитьПараметр("Идентификатор", ОбъектМодели.ПолучитьЗначениеИдентификатора(Сущность));
	Запрос.ВыполнитьКоманду();
	
КонецПроцедуры

// Осуществляет поиск строк в таблице по указанному отбору.
//
// Параметры:
//   ОбъектМодели - ОбъектМодели - Объект, содержащий описание класса-сущности и настроек таблицы БД.
//   Отбор - Массив - Отбор для поиска. Каждый элемент массива должен иметь тип "ЭлементОтбора".
//       Каждый элемент отбора преобразуется к условию поиска. В качестве "ПутьКДанным" указываются имена колонок.
//
//  Возвращаемое значение:
//   Массив - Массив, элементами которого являются "Соответствия". Ключом элемента соответствия является имя колонки,
//     значением элемента соответствия - значение колонки.
//
Функция НайтиСтрокиВТаблице(ОбъектМодели, Знач Отбор) Экспорт
	
	НайденныеСтроки = Новый Массив;
	Колонки = ОбъектМодели.Колонки();
	
	Запрос = КонструкторКоннектора.НовыйЗапрос(Соединение);
	
	ТекстЗапроса = СтрШаблон(
		"SELECT * FROM %1",
		ОбъектМодели.ИмяТаблицы()
	);
	
	СтрокаУсловий = "";
	
	Для сч = 0 По Отбор.ВГраница() Цикл
		ЭлементОтбора = Отбор[сч];
		ПредставлениеСчетчика = "п" + Формат(сч + 1, "ЧН=0; ЧГ=");
		Если ЗначениеЗаполнено(СтрокаУсловий) Тогда
			СтрокаУсловий = СтрокаУсловий + Символы.ПС + Символы.Таб + "AND ";
		КонецЕсли;
		СтрокаУсловий = СтрокаУсловий + СтрШаблон(
			"%1 %2 @%3", 
			ЭлементОтбора.ПутьКДанным, 
			ЭлементОтбора.ВидСравнения, 
			ПредставлениеСчетчика
		);
		Запрос.УстановитьПараметр(ПредставлениеСчетчика, ЭлементОтбора.Значение);
	КонецЦикла;
	
	Если ЗначениеЗаполнено(СтрокаУсловий) Тогда
		ТекстЗапроса = ТекстЗапроса + Символы.ПС + "WHERE " + СтрокаУсловий;
	КонецЕсли;
	
	Лог.Отладка("Поиск сущности в таблице %1:%2%3", ОбъектМодели.ИмяТаблицы(), Символы.ПС, ТекстЗапроса);
	
	Запрос.Текст = ТекстЗапроса;
	Результат = Запрос.Выполнить().Выгрузить();
	
	Если Результат.Количество() = 0 Тогда
		Лог.Отладка("Сущность с типом %1 не найдена", ОбъектМодели.ТипСущности());
		Возврат НайденныеСтроки;
	КонецЕсли;
	
	Для Каждого СтрокаИзБазы Из Результат Цикл
		ЗначенияКолонок = Новый Соответствие;
		
		Для Каждого Колонка Из Колонки Цикл
			
			ЗначениеКолонки = СтрокаИзБазы[Колонка.ИмяКолонки];
			ЗначенияКолонок.Вставить(Колонка.ИмяКолонки, ЗначениеКолонки);
		
		КонецЦикла;
		
		НайденныеСтроки.Добавить(ЗначенияКолонок);
	КонецЦикла;
	
	Возврат НайденныеСтроки;
	
КонецФункции

// Удаляет строки в таблице по указанному отбору.
//
// Параметры:
//   ОбъектМодели - ОбъектМодели - Объект, содержащий описание класса-сущности и настроек таблицы БД.
//   Отбор - Массив - Отбор для поиска. Каждый элемент массива должен иметь тип "ЭлементОтбора".
//       Каждый элемент отбора преобразуется к условию поиска. В качестве "ПутьКДанным" указываются имена колонок.
//
Процедура УдалитьСтрокиВТаблице(ОбъектМодели, Знач Отбор) Экспорт
	
	НайденныеСтроки = Новый Массив;
	Колонки = ОбъектМодели.Колонки();
	
	Запрос = КонструкторКоннектора.НовыйЗапрос(Соединение);
	
	ТекстЗапроса = СтрШаблон(
		"DELETE FROM %1",
		ОбъектМодели.ИмяТаблицы()
	);
	
	СтрокаУсловий = "";
	
	Для сч = 0 По Отбор.ВГраница() Цикл
		ЭлементОтбора = Отбор[сч];
		ПредставлениеСчетчика = "п" + Формат(сч + 1, "ЧН=0; ЧГ=");
		Если ЗначениеЗаполнено(СтрокаУсловий) Тогда
			СтрокаУсловий = СтрокаУсловий + Символы.ПС + Символы.Таб + "AND ";
		КонецЕсли;
		СтрокаУсловий = СтрокаУсловий
			+ СтрШаблон("%1 %2 @%3", ЭлементОтбора.ПутьКДанным, ЭлементОтбора.ВидСравнения, ПредставлениеСчетчика);
		Запрос.УстановитьПараметр(ПредставлениеСчетчика, ЭлементОтбора.Значение);
	КонецЦикла;
	
	Если ЗначениеЗаполнено(СтрокаУсловий) Тогда
		ТекстЗапроса = ТекстЗапроса + Символы.ПС + "WHERE " + СтрокаУсловий;
	КонецЕсли;
	
	Лог.Отладка("Удаление сущностей в таблице %1:%2%3", ОбъектМодели.ИмяТаблицы(), Символы.ПС, ТекстЗапроса);
	
	Запрос.Текст = ТекстЗапроса;
	Запрос.ВыполнитьКоманду();
	
КонецПроцедуры

// @Unstable
// Выполнить произвольный запрос и получить результат.
//
// Данный метод не входит в основной интерфейс "Коннектор".
// Не рекомендуется использовать этот метод в прикладном коде, сигнатура метода может измениться.
//
// Параметры:
//   ТекстЗапроса - Строка - Текст выполняемого запроса
//
//  Возвращаемое значение:
//   ТаблицаЗначений - Результат выполнения запроса.
//
Функция ВыполнитьЗапрос(ТекстЗапроса) Экспорт
	
	Лог.Отладка("Выполнение запроса:%1%2", Символы.ПС, ТекстЗапроса);
	
	// TODO: Стоит вынести в сам менеджер?
	Запрос = КонструкторКоннектора.НовыйЗапрос(Соединение);
	Запрос.Текст = ТекстЗапроса;
	Результат = Запрос.Выполнить().Выгрузить();
	
	Возврат Результат;
	
КонецФункции

Функция СоответствиеТиповМоделиИТиповКолонок()
	
	Карта = Новый Соответствие;
	Карта.Вставить(ТипыКолонок.Целое, "INTEGER");
	Карта.Вставить(ТипыКолонок.Дробное, "DECIMAL");
	Карта.Вставить(ТипыКолонок.Булево, "BOOLEAN");
	Карта.Вставить(ТипыКолонок.Строка, "TEXT");
	Карта.Вставить(ТипыКолонок.Дата, "DATE");
	Карта.Вставить(ТипыКолонок.Время, "TIME");
	Карта.Вставить(ТипыКолонок.ДатаВремя, "DATETIME");
	
	Возврат Карта;
	
КонецФункции

Функция ПолучитьТипКолонкиСУБД(ОбъектМодели, КолонкаМодели)
	ТипКолонкиСУБД = Неопределено;
	
	Если КолонкаМодели.ТипКолонки = ТипыКолонок.Ссылка Тогда
		ОбъектМоделиСсылка = ОбъектМодели.МодельДанных().Получить(КолонкаМодели.ТипСсылки);
		ТипКолонкиСУБД = КартаТипов.Получить(ОбъектМоделиСсылка.Идентификатор().ТипКолонки);
	ИначеЕсли ТипыКолонок.ЭтоПримитивныйТип(КолонкаМодели.ТипКолонки) Тогда
		ТипКолонкиСУБД = КартаТипов.Получить(КолонкаМодели.ТипКолонки);
	Иначе
		ВызватьИсключение "Неизвестный тип колонки " + КолонкаМодели.ТипКолонки;
	КонецЕсли;
	
	Возврат ТипКолонкиСУБД;
КонецФункции

Функция ПолучитьОписаниеВнешнегоКлюча(ОбъектМодели, КолонкаМодели)
	СтрокаВнешнийКлюч = "";
	
	Если КолонкаМодели.ТипКолонки = ТипыКолонок.Ссылка Тогда
		ОбъектМоделиСсылка = ОбъектМодели.МодельДанных().Получить(КолонкаМодели.ТипСсылки);
		
		СтрокаВнешнийКлюч = Символы.Таб + СтрШаблон(
			"FOREIGN KEY (%1) REFERENCES %2(%3),%4",
			КолонкаМодели.ИмяКолонки,
			ОбъектМоделиСсылка.ИмяТаблицы(),
			ОбъектМоделиСсылка.Идентификатор().ИмяКолонки,
			Символы.ПС
		);
	КонецЕсли;
	
	Возврат СтрокаВнешнийКлюч;
КонецФункции

#Область Подключение_коннектора_СУБД

Функция ПолучитьКонструкторКоннектора() 
	
	ПутьККлассам = ОбъединитьПути(
		ТекущийСценарий().Каталог,
		"..",
		"internal",
		"ДинамическиПодключаемыеКлассы"
	);

	Попытка
		А = Вычислить("ПользователиИнформационнойБазы");
		ПутьККоннектору = ОбъединитьПути(
			ПутьККлассам,
			"КонструкторКоннектораSQLiteWeb.os"
		);
	Исключение
		ПутьККоннектору = ОбъединитьПути(
			ПутьККлассам,
			"КонструкторКоннектораSQLite.os"
		);
	КонецПопытки;

	Возврат ЗагрузитьСценарий(ПутьККоннектору);
	
КонецФункции

#КонецОбласти
