# Thread-Safe Transactions

Starting from version 3.5.0, the Entity library supports thread-safe transactions through connection pooling with a simplified API.

## Problem

In the previous version, all entity managers and repositories shared a single connector instance. This caused race conditions when multiple threads used transactions:

```bsl
// Thread 1 and Thread 2 both use the same connector
Thread1: МенеджерСущностей.НачатьТранзакцию(); 
Thread2: МенеджерСущностей.НачатьТранзакцию(); // Overwrites Thread 1's transaction
Thread1: МенеджерСущностей.ЗафиксироватьТранзакцию(); // Commits Thread 2's work instead!
```

## Solution

The library now supports connection pooling with automatic context management. Each transaction gets its own context and connector, ensuring thread safety without complex parameter passing.

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

### Simplified Thread-Safe Transactions

```bsl
// Simple approach - library automatically manages contexts
КонтекстID = МенеджерСущностей.НачатьТранзакцию();

// All CRUD operations can optionally use the context
МенеджерСущностей.Сохранить(Сущность, КонтекстID);
ЗагруженныеСущности = МенеджерСущностей.Получить(Тип("МояСущность"), Неопределено, КонтекстID);

// Commit the transaction
МенеджерСущностей.ЗафиксироватьТранзакцию(КонтекстID);
```

### Multiple Concurrent Transactions

```bsl
// Thread 1: 
КонтекстID1 = МенеджерСущностей.НачатьТранзакцию();
МенеджерСущностей.Сохранить(Сущность1, КонтекстID1);

// Thread 2: Independent transaction
КонтекстID2 = МенеджерСущностей.НачатьТранзакцию();  
МенеджерСущностей.Сохранить(Сущность2, КонтекстID2);

// Each thread commits independently
МенеджерСущностей.ЗафиксироватьТранзакцию(КонтекстID1); // Thread 1
МенеджерСущностей.ОтменитьТранзакцию(КонтекстID2); // Thread 2
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

### CRUD Operations

All CRUD operations support optional context parameters:

```bsl
// Without context (uses default connector)
МенеджерСущностей.Сохранить(Сущность);
Результат = МенеджерСущностей.Получить(Тип("МояСущность"));

// With context (uses transaction-specific connector)
МенеджерСущностей.Сохранить(Сущность, КонтекстID);
Результат = МенеджерСущностей.Получить(Тип("МояСущность"), ОпцииПоиска, КонтекстID);
МенеджерСущностей.Удалить(Сущность, КонтекстID);
```

## Connection Pool Configuration

- **Pool Size**: Determines the maximum number of concurrent connections
- **Default**: Pool is disabled (backward compatibility)  
- **Recommendation**: Set pool size to expected number of concurrent threads

## Key Features

- **Simplified API**: No need to manually manage connection objects
- **Automatic Context Management**: Connectors are automatically assigned to contexts
- **Backward Compatibility**: All existing code works unchanged
- **Thread Safety**: Each transaction context is isolated
- **Performance**: Connection reuse minimizes database connection overhead