# Thread-Safe Transactions

Starting from version 3.5.0, the Entity library supports thread-safe transactions through connection pooling.

## Problem

In the previous version, all entity managers and repositories shared a single connector instance. This caused race conditions when multiple threads used transactions:

```bsl
// Thread 1 and Thread 2 both use the same connector
Thread1: МенеджерСущностей.НачатьТранзакцию(); 
Thread2: МенеджерСущностей.НачатьТранзакцию(); // Overwrites Thread 1's transaction
Thread1: МенеджерСущностей.ЗафиксироватьТранзакцию(); // Commits Thread 2's work instead!
```

## Solution

The library now supports connection pooling. Each connection has its own transaction state, ensuring thread safety.

## Usage

### Creating Entity Manager with Connection Pool

```bsl
// Create entity manager with connection pool of size 5
МенеджерСущностей = Новый МенеджерСущностей(
    Тип("КоннекторPostgreSQL"), 
    "Host=localhost;Port=5432;Database=test", 
    Неопределено, // Parameters
    5 // Pool size
);
```

### Thread-Safe Transactions

```bsl
// Thread 1: Get connection from pool
Соединение1 = МенеджерСущностей.НачатьТранзакцию();

// Thread 2: Get different connection from pool  
Соединение2 = МенеджерСущностей.НачатьТранзакцию();

// Each thread works with its own connection
МенеджерСущностей.Сохранить(Сущность1, Соединение1);
МенеджерСущностей.Сохранить(Сущность2, Соединение2);

// Thread 1: Commit only its transaction
МенеджерСущностей.ЗафиксироватьТранзакцию(Соединение1);

// Thread 2: Rollback only its transaction
МенеджерСущностей.ОтменитьТранзакцию(Соединение2);
```

### Manual Connection Management

```bsl
// Get connection from pool for custom operations
Соединение = МенеджерСущностей.ПолучитьСоединение();

// Use for CRUD operations
МенеджерСущностей.Сохранить(Сущность, Соединение);
МенеджерСущностей.Получить(Тип("МояСущность"), ОпцииПоиска, Соединение);

// Always return connection to pool when done
МенеджерСущностей.ВернутьСоединение(Соединение);
```

### Repository Usage

```bsl
ХранилищеСущностей = МенеджерСущностей.ПолучитьХранилищеСущностей(Тип("МояСущность"));

// Thread-safe transaction through repository
Соединение = ХранилищеСущностей.НачатьТранзакцию();
ХранилищеСущностей.Сохранить(Сущность, Соединение);
ХранилищеСущностей.ЗафиксироватьТранзакцию(Соединение);
```

## Backward Compatibility

All existing code continues to work without modification:

```bsl
// Old API still works (uses shared connector)
МенеджерСущностей = Новый МенеджерСущностей(Тип("КоннекторPostgreSQL"), "connection_string");
МенеджерСущностей.НачатьТранзакцию();
МенеджерСущностей.Сохранить(Сущность);
МенеджерСущностей.ЗафиксироватьТранзакцию();
```

## Connection Pool Configuration

- **Pool Size**: Determines the maximum number of concurrent connections
- **Default**: Pool is disabled (backward compatibility)
- **Recommendation**: Set pool size to expected number of concurrent threads

## Performance Considerations

- Each connection in the pool maintains its own database connection
- Connections are reused to minimize connection overhead
- Pool automatically expands when more connections are needed than pool size
- Unused connections are closed when returned to an oversized pool