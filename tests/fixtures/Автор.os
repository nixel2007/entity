&Идентификатор
&ГенерируемоеЗначение
&Колонка(Имя = "Идентификатор", Тип = "Целое")
Перем ВнутреннийИдентификатор Экспорт;

Перем Имя Экспорт;

&Колонка(Имя = "Фамилия")
Перем ВтороеИмя Экспорт;

&Колонка(Тип = "Ссылка", ТипЭлемента = "СущностьБезГенерируемогоИдентификатора")
Перем ВнешняяСущность Экспорт;

&Сущность(ИмяТаблицы = "Авторы")
Процедура ПриСозданииОбъекта()

КонецПроцедуры
