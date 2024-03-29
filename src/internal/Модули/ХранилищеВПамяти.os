
Перем КешиТаблиц;

Функция КешТаблиц(СтрокаПодключения = "default") Экспорт
	Результат = КешиТаблиц.Получить(СтрокаПодключения);

	Если Результат = Неопределено Тогда
		Результат = Новый Соответствие();
		КешиТаблиц.Вставить(СтрокаПодключения, Результат);
	КонецЕсли;

	Возврат Результат;

КонецФункции

Процедура Очистить(СтрокаПодключения = "default") Экспорт
	КешиТаблиц.Вставить(СтрокаПодключения, Новый Соответствие());
КонецПроцедуры

Процедура Инициализация()
	КешиТаблиц = Новый Соответствие();
КонецПроцедуры

Инициализация();