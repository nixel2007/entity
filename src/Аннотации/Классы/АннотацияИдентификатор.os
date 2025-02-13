// Каждый класс, подключаемый к менеджеру сущностей, должен иметь поле для хранения 
// идентификатора объекта в СУБД - первичного ключа.
//
// Для формирования автоинкрементного первичного ключа можно воспользоваться
// дополнительной аннотацией `&ГенерируемоеЗначение`.
//
// Применяется на поле класса.
//
// Пример:
// 
// &Идентификатор
// Перем ИД;
//
&Аннотация("Идентификатор")
Процедура ПриСозданииОбъекта()
КонецПроцедуры
