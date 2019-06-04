Функция НовыйСоединение() Экспорт
	Возврат ИнформационнаяБаза;
КонецФункции

Процедура Открыть(Соединение, СтрокаСоединения) Экспорт
	// no-op
КонецПроцедуры

Процедура Закрыть(Соединение) Экспорт
	// no-op
КонецПроцедуры

Функция НовыйЗапрос(Соединение) Экспорт
	Запрос = Новый Запрос();
	Запрос.УстановитьСоединение(Соединение);
	Возврат Запрос;
КонецФункции

Функция ИДПоследнейДобавленнойЗаписи(Соединение, Запрос) Экспорт
	
	ИДПоследнейДобавленнойЗаписи = Запрос.ИДПоследнейДобавленнойЗаписи();

	Запрос.Текст = СтрШаблон("SELECT max(%1) FROM %2", Параметры.ИмяКолонки, Параметры.ИмяТаблицы);
	Рез = Запрос.Выполнить().Выгрузить();
	Если Рез.Количество() > 0 Тогда
		ИДПоследнейДобавленнойЗаписи = Рез[0]["max"];
	КонецЕсли;

	Возврат ИДПоследнейДобавленнойЗаписи;
	
КонецФункции