#Использовать asserts
#Использовать logos
#Использовать reflector
#Использовать semaphore
#Использовать strings

Перем КоннекторSQL;
Перем КонструкторКоннектора Экспорт;
Перем Соединение Экспорт;
Перем КартаТипов;

Перем Лог;

// Конструктор объекта КоннекторSQLite.
//
Процедура ПриСозданииОбъекта()

	Лог = Логирование.ПолучитьЛог("oscript.lib.entity.connector.sqlite");
	КоннекторSQL = Новый АбстрактныйКоннекторSQL(ЭтотОбъект, Лог);

	КонструкторКоннектора = ПолучитьКонструкторКоннектора();
	Соединение = КонструкторКоннектора.НовыйСоединение();
	КартаТипов = СоответствиеТиповМоделиИТиповКолонок();
	
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
	
	КоннекторSQL.ИнициализироватьТаблицу(ОбъектМодели);
	
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
	
	Попытка
		
		Запрос.ВыполнитьКоманду();

		Если ОбъектМодели.Идентификатор().ГенерируемоеЗначение Тогда
			ИДПоследнейДобавленнойЗаписи = КонструкторКоннектора.ИДПоследнейДобавленнойЗаписи(Соединение, Запрос);
			ОбъектМодели.УстановитьЗначениеКолонкиВПоле(
				Сущность,
				ОбъектМодели.Идентификатор().ИмяКолонки,
				ИДПоследнейДобавленнойЗаписи
			);
		КонецЕсли;

	Исключение
		
		Семафор.Освободить();

		ВызватьИсключение;

	КонецПопытки;
	
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
	
	КоннекторSQL.Удалить(ОбъектМодели, Сущность);
	
КонецПроцедуры

// Осуществляет поиск строк в таблице по указанному отбору.
//
// Параметры:
//   ОбъектМодели - ОбъектМодели - Объект, содержащий описание класса-сущности и настроек таблицы БД.
//   ОпцииПоиска - ОпцииПоиска - Опции поиска. Содержит следующие параметры:
//     * Отборы - Массив - Отбор для поиска. Каждый элемент массива должен иметь тип "ЭлементОтбора".
//                         Каждый элемент отбора преобразуется к условию поиска.
//                         В качестве "ПутьКДанным" указываются имена колонок.
//     * Сортировки - Массив - Сортировка для результата поиска.
//                             Каждый элемент массива должен иметь тип "ЭлементПорядка".
//                             В качестве "ПутьКДанным" указываются имена колонок.
//
//  Возвращаемое значение:
//   Массив - Массив, элементами которого являются "Соответствия". Ключом элемента соответствия является имя колонки,
//     значением элемента соответствия - значение колонки.
//
Функция НайтиСтрокиВТаблице(ОбъектМодели, ОпцииПоиска) Экспорт
	
	Возврат КоннекторSQL.НайтиСтрокиВТаблице(ОбъектМодели, ОпцииПоиска);
	
КонецФункции

// Удаляет строки в таблице по указанному отбору.
//
// Параметры:
//   ОбъектМодели - ОбъектМодели - Объект, содержащий описание класса-сущности и настроек таблицы БД.
//   ОпцииПоиска - ОпцииПоиска - Опции поиска. Содержит следующие параметры:
//     * Отборы - Массив - Отбор для поиска. Каждый элемент массива должен иметь тип "ЭлементОтбора".
//                         Каждый элемент отбора преобразуется к условию поиска.
//                         В качестве "ПутьКДанным" указываются имена колонок.
//
Процедура УдалитьСтрокиВТаблице(ОбъектМодели, ОпцииПоиска) Экспорт
	
	КоннекторSQL.УдалитьСтрокиВТаблице(ОбъектМодели, ОпцииПоиска);
	
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
	
	Возврат КоннекторSQL.ВыполнитьЗапрос(ТекстЗапроса);
	
КонецФункции

Функция СоответствиеТиповМоделиИТиповКолонок()

	Перем Карта;

	Карта = Новый Соответствие;
	Карта.Вставить(ТипыКолонок.Целое, "INTEGER");
	Карта.Вставить(ТипыКолонок.Дробное, "DECIMAL");
	Карта.Вставить(ТипыКолонок.Булево, "BOOLEAN");
	Карта.Вставить(ТипыКолонок.Строка, "TEXT");
	Карта.Вставить(ТипыКолонок.Дата, "DATE");
	Карта.Вставить(ТипыКолонок.Время, "TIME");
	Карта.Вставить(ТипыКолонок.ДатаВремя, "DATETIME");
	Карта.Вставить(ТипыКолонок.ДвоичныеДанные, "BLOB");
	
	Возврат Карта;
	
КонецФункции

Функция ПолучитьТипКолонкиСУБД(ОбъектМодели, КолонкаМодели) Экспорт
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

Функция ПолучитьОписаниеВнешнегоКлюча(ОбъектМодели, КолонкаМодели) Экспорт

	Возврат КоннекторSQL.ПолучитьОписаниеВнешнегоКлюча(ОбъектМодели, КолонкаМодели);

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
