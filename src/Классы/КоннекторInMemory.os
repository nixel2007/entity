#Использовать "../internal"
#Использовать fluent

// Для хранения статуса соединения
Перем Открыт;
Перем КешТаблиц;
Перем Рефлектор;

// Конструктор объекта АбстрактныйКоннектор.
//
Процедура ПриСозданииОбъекта()
	Открыт = Ложь;
	Рефлектор = Новый Рефлектор;
КонецПроцедуры

// Открыть соединение с БД.
//
// Параметры:
//   СтрокаСоединения - Строка - Строка соединения с БД.
//   ПараметрыКоннектора - Массив - Дополнительные параметры инициализации коннектора.
//
Процедура Открыть(СтрокаСоединения, ПараметрыКоннектора) Экспорт // BSLLS:UnusedParameters-off
	КешТаблиц = ХранилищеВПамяти.КешТаблиц(СтрокаСоединения);
	Открыт = Истина;
КонецПроцедуры

// Закрыть соединение с БД.
//
Процедура Закрыть() Экспорт
	Открыт = Ложь;
КонецПроцедуры

// Получить статус соединения с БД.
//
//  Возвращаемое значение:
//   Булево - Состояние соединения. Истина, если соединение установлено и готово к использованию.
//       В обратном случае - Ложь.
//
Функция Открыт() Экспорт
	Возврат Открыт;
КонецФункции

// Начинает новую транзакцию в БД.
//
Процедура НачатьТранзакцию() Экспорт
	ВызватьИсключение "Не поддерживается";
КонецПроцедуры

// Фиксирует открытую транзакцию в БД.
//
Процедура ЗафиксироватьТранзакцию() Экспорт
	ВызватьИсключение "Не поддерживается";
КонецПроцедуры

// Отменяет открытую транзакцию в БД.
//
Процедура ОтменитьТранзакцию() Экспорт
	ВызватьИсключение "Не поддерживается";
КонецПроцедуры

// Создает таблицу в БД по данным модели.
//
// Параметры:
//   ОбъектМодели - ОбъектМодели - Объект, содержащий описание класса-сущности и настроек таблицы БД.
//
Процедура ИнициализироватьТаблицу(ОбъектМодели) Экспорт
	ИмяТаблицы = ОбъектМодели.ИмяТаблицы();

	Если КешТаблиц.Получить(ИмяТаблицы) = Неопределено Тогда
		Таблица = Новый ТаблицаЗначений();

		Таблица.Колонки.Добавить("_Идентификатор");
		Таблица.Колонки.Добавить("_Сущность");

		Таблица.Индексы.Добавить("_Идентификатор");
		
		КешТаблиц.Вставить(ИмяТаблицы, Таблица);
	КонецЕсли;

КонецПроцедуры

// Сохраняет сущность в БД.
//
// Параметры:
//   ОбъектМодели - ОбъектМодели - Объект, содержащий описание класса-сущности и настроек таблицы БД.
//   Сущность - Произвольный - Объект (экземпляр класса, зарегистрированного в модели) для сохранения в БД.
//
Процедура Сохранить(ОбъектМодели, Сущность) Экспорт

	ИмяТаблицы = ОбъектМодели.ИмяТаблицы();

	Таблица = КешТаблиц.Получить(ИмяТаблицы);

	Если Таблица = Неопределено Тогда
		ВызватьИсключение "Таблица " + ИмяТаблицы + " не найдена";
	КонецЕсли;

	Идентификатор = ОбъектМодели.ПолучитьЗначениеИдентификатора(Сущность);
	Если НЕ ЗначениеЗаполнено(Идентификатор) Тогда
		
		Если ОбъектМодели.Идентификатор().ТипКолонки <> ТипыКолонок.Целое Тогда
			Сообщение = СтрШаблон(
				"Ошибка при сохранении сущности с типом %1.
				|Генерация идентификаторов поддерживается только для колонок с типом ""Целое""",
				ОбъектМодели.ТипСущности()
			);
			ВызватьИсключение Сообщение;
		КонецЕсли;

		МаксимальныйИдентификатор = ПроцессорыКоллекций.ИзКоллекции(Таблица)
		    .Обработать("Элемент -> Число(Элемент._Идентификатор)")
			.Максимум();
		
		Если МаксимальныйИдентификатор = Неопределено Тогда
			МаксимальныйИдентификатор = 0;
		КонецЕсли;

		Идентификатор = МаксимальныйИдентификатор + 1;

		ОбъектМодели.УстановитьЗначениеКолонкиВПоле(
			Сущность,
			ОбъектМодели.Идентификатор().ИмяКолонки,
			Идентификатор
		);

	КонецЕсли;
	Если ТипЗнч(Идентификатор) = Тип("Число") Тогда
		Идентификатор = Формат(Идентификатор, "ЧГ=");
	КонецЕсли;

	СтрокаТЗ = Таблица.Найти(Идентификатор, "_Идентификатор");

	Если СтрокаТЗ = Неопределено Тогда
		СтрокаТЗ = Таблица.Добавить();
	КонецЕсли;

	СущностьВБД = Новый (ОбъектМодели.ТипСущности());

	Для Каждого Колонка Из ОбъектМодели.Колонки() Цикл
		Значение = ОбъектМодели.ПолучитьПриведенноеЗначениеПоля(
									Сущность, 
									Колонка.ИмяПоля);
		Рефлектор.УстановитьСвойство(СущностьВБД, Колонка.ИмяПоля, Значение);
	КонецЦикла;

	СтрокаТЗ._Идентификатор = Идентификатор;
	СтрокаТЗ._Сущность = СущностьВБД;
	
КонецПроцедуры

// Удаляет сущность из таблицы БД.
//
// Параметры:
//   ОбъектМодели - ОбъектМодели - Объект, содержащий описание класса-сущности и настроек таблицы БД.
//   Сущность - Произвольный - Объект (экземпляр класса, зарегистрированного в модели) для удаления из БД.
//
Процедура Удалить(ОбъектМодели, Сущность) Экспорт
	
	ИмяТаблицы = ОбъектМодели.ИмяТаблицы();

	Таблица = КешТаблиц.Получить(ИмяТаблицы);

	Если Таблица = Неопределено Тогда
		ВызватьИсключение "Таблица " + ИмяТаблицы + " не найдена";
	КонецЕсли;

	Идентификатор = ОбъектМодели.ПолучитьЗначениеИдентификатора(Сущность);
	Если ТипЗнч(Идентификатор) = Тип("Число") Тогда
		Идентификатор = Формат(Идентификатор, "ЧГ=");
	КонецЕсли;

	СтрокаТЗ = Таблица.Найти(Идентификатор, "_Идентификатор");

	Если НЕ СтрокаТЗ = Неопределено Тогда
		Таблица.Удалить(СтрокаТЗ);
	КонецЕсли;

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
	
	ИмяТаблицы = ОбъектМодели.ИмяТаблицы();
	Отборы = ОпцииПоиска.Отборы();
	Сортировки = ОпцииПоиска.Сортировки();

	Таблица = КешТаблиц.Получить(ИмяТаблицы);

	Если Таблица = Неопределено Тогда
		ВызватьИсключение "Таблица " + ИмяТаблицы + " не найдена";
	КонецЕсли;

	ПроцессорКоллекций = ПроцессорыКоллекций.ИзКоллекции(Таблица);

	Колонки = ОбъектМодели.Колонки();
	
	Для Каждого ЭлементОтбора Из Отборы Цикл

		НайденныеКолонки = Колонки.НайтиСтроки(Новый Структура("ИмяКолонки", ЭлементОтбора.ПутьКДанным));

		Если НайденныеКолонки.Количество() = 0 Тогда
			ИмяПоля = ЭлементОтбора.ПутьКДанным;
		Иначе
			ИмяПоля = НайденныеКолонки[0].ИмяПоля;
		КонецЕсли;

		Если ЭлементОтбора.ВидСравнения = ВидСравнения.В Тогда
			СтрокаУсловие = СтрШаблон(
				"Элемент -> Значение.Найти(Элемент._Сущность.%1) <> Неопределено",
				ЭлементОтбора.ПутьКДанным
			);
		Иначе
			СтрокаУсловие = СтрШаблон(
				"Элемент -> Элемент._Сущность.%1 %2 Значение",
				ИмяПоля,
				ЭлементОтбора.ВидСравнения
			);
		КонецЕсли;

		ДополнительныеПараметры = Новый Структура("Значение", ЭлементОтбора.Значение);
		ПроцессорКоллекций = ПроцессорКоллекций.Фильтровать(СтрокаУсловие, ДополнительныеПараметры);
	КонецЦикла;

	СтрокаСортировка = "";
	Для Каждого ЭлементПорядка Из Сортировки Цикл

		НайденныеКолонки = Колонки.НайтиСтроки(Новый Структура("ИмяКолонки", ЭлементПорядка.ПутьКДанным));

		Если НайденныеКолонки.Количество() = 0 Тогда
			ИмяПоля = ЭлементПорядка.ПутьКДанным;
		Иначе
			ИмяПоля = НайденныеКолонки[0].ИмяПоля;
		КонецЕсли;
		ПорядокСортировки = ?(ЭлементПорядка.НаправлениеСортировки = НаправлениеСортировки.Возр,
			"ПрямойПорядок", 
			"ОбратныйПорядок"
		);

		// формирование текста лямбды для сравнения элементов по нескольким полям
		СтрокаСортировка = СтрокаСортировка + СтрШаблон(
			"Сравнение = ПроцессорыКоллекцийСлужебный.СравнениеЗначений%1(Элемент1._Сущность.%2, Элемент2._Сущность.%2);
			|Если Сравнение <> 0 Тогда
			|	Возврат Сравнение;
			|КонецЕсли;
			|
			|",
			ПорядокСортировки,
			ИмяПоля
		);

	КонецЦикла;

	Если СтрокаСортировка <> "" Тогда
		СтрокаСортировка = "(Элемент1, Элемент2) -> " + Символы.ПС + СтрокаСортировка + "Возврат Сравнение;";

		ПроцессорКоллекций = ПроцессорКоллекций.Сортировать(СтрокаСортировка);
	КонецЕсли;

	ДанныеТаблицы = ПроцессорКоллекций.ВМассив();

	Результат = Новый Массив();

	Колонки = ОбъектМодели.Колонки();
	
	Для Каждого СтрокаДанныхТаблицы Из ДанныеТаблицы Цикл
		ЗначенияКолонок = Новый Соответствие;
		Для Каждого Колонка Из Колонки Цикл
			Значение = Рефлектор.ПолучитьСвойство(СтрокаДанныхТаблицы._Сущность, Колонка.ИмяПоля);
			ЗначенияКолонок.Вставить(Колонка.ИмяКолонки, Значение);
		КонецЦикла;
		Результат.Добавить(ЗначенияКолонок);
	КонецЦикла;

	Возврат Результат;

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

	СтрокиКУдалению = НайтиСтрокиВТаблице(ОбъектМодели, ОпцииПоиска);
	Если СтрокиКУдалению.Количество() > 0 Тогда

		ИмяКолонкиИдентификатора = ОбъектМодели.Идентификатор().ИмяКолонки;
		
		ИмяТаблицы = ОбъектМодели.ИмяТаблицы();
		Таблица = КешТаблиц.Получить(ИмяТаблицы);

		Для Каждого СтрокаКУдалению Из СтрокиКУдалению Цикл
			Идентификатор = СтрокаКУдалению.Получить(ИмяКолонкиИдентификатора);
			Если ТипЗнч(Идентификатор) = Тип("Число") Тогда
				Идентификатор = Формат(Идентификатор, "ЧГ=");
			КонецЕсли;

			СтрокаТЗ = Таблица.Найти(Идентификатор, "_Идентификатор");

			Если НЕ СтрокаТЗ = Неопределено Тогда
				Таблица.Удалить(СтрокаТЗ);
			КонецЕсли;
		КонецЦикла;

	КонецЕсли;
КонецПроцедуры
