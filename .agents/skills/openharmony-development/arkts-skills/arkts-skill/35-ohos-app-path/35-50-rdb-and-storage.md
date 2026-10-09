# Relational database (RDB) storage

Use this when the blocker is storing or querying persistent data with `@ohos.data.relationalStore`.

## Load this doc when you see
- `relationalStore`, `RdbStore`, `ResultSet`, `ValuesBucket`
- `getRdbStore`, `STORE_CONFIG`, `SQL_CREATE_TABLE`
- `.execute()`, `.insert()`, `.batchInsert()`, `.querySql()`

## Return rule
- if the blocker is only how to access the app context to open the store, check the `getHostContext()` pattern in `../35-10-app-model-and-system-apis.md`
- if the DB call freezes the UI, offload it to taskpool via `../../20-references/28-taskpool-and-synchronization.md`

## Open or create one database
```ts
import relationalStore from '@ohos.data.relationalStore'
import common from '@ohos.app.ability.common'

const STORE_CONFIG: relationalStore.StoreConfig = {
    name: 'contacts.db',
    securityLevel: relationalStore.SecurityLevel.S1
}

const SQL_CREATE_TABLE: string = `
    CREATE TABLE IF NOT EXISTS contact (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        phone TEXT,
        email TEXT,
        address TEXT
    )
`

async function initDB(context: common.Context): Promise<relationalStore.RdbStore> {
    let store = await relationalStore.getRdbStore(context, STORE_CONFIG)
    await store.execute(SQL_CREATE_TABLE)
    return store
}
```

## Insert one row
```ts
import { ValuesBucket } from '@ohos.data.ValuesBucket'

async function insertContact(store: relationalStore.RdbStore, name: string, phone: string): Promise<void> {
    let values: ValuesBucket = {
        'name': name,
        'phone': phone
    }
    await store.insert('contact', values, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
}
```

## Batch-insert many rows
```ts
async function batchInsert(store: relationalStore.RdbStore, contacts: Contact[]): Promise<number> {
    let buckets: ValuesBucket[] = []
    for (let i: int = 0; i < contacts.length; i++) {
        let item = contacts[i]
        buckets.push({
            'name': item.name,
            'phone': item.phone,
            'email': item.email,
            'address': item.address
        } as ValuesBucket)
    }
    return await store.batchInsert('contact', buckets) as number
}

class Contact {
    name: string = ''
    phone: string = ''
    email: string = ''
    address: string = ''
}
```

## Query rows and walk the result set
```ts
async function queryAll(store: relationalStore.RdbStore): Promise<Contact[]> {
    let resultSet: relationalStore.ResultSet = await store.querySql('SELECT * FROM contact')
    let contacts: Contact[] = []

    while (resultSet.goToNextRow()) {
        let contact = new Contact()
        contact.name = resultSet.getString(resultSet.getColumnIndex('name'))
        contact.phone = resultSet.getString(resultSet.getColumnIndex('phone'))
        contact.email = resultSet.getString(resultSet.getColumnIndex('email'))
        contact.address = resultSet.getString(resultSet.getColumnIndex('address'))
        contacts.push(contact)
    }
    resultSet.close()
    return contacts
}
```

## Update or delete with bound parameters
```ts
async function deleteContact(store: relationalStore.RdbStore, name: string): Promise<void> {
    await store.execute('DELETE FROM contact WHERE name = ?', [name])
}

async function updatePhone(store: relationalStore.RdbStore, name: string, newPhone: string): Promise<void> {
    await store.execute(
        'UPDATE contact SET phone = ? WHERE name = ?',
        [newPhone, name]
    )
}
```

## DB open fails because the context is wrong
```text
getRdbStore or execute throws a null-context or permission error
```
Next move:
- verify the context comes from `getHostContext() as common.UIAbilityContext`
- verify the context was stored by `EntryAbility.onCreate(...)` via the `GlobalContext` pattern

## Verify
- open the store, insert one row, query it back
- prove the close + reopen cycle preserves data
- if a DB call freezes the UI, offload it to taskpool

## Compress or decompress one sandbox file -> `@ohos.zlib`
```ts
import zlib from '@ohos.zlib'

await zlib.compressFile('/path/to/src.txt', '/path/to/dst.zip', {
    level: zlib.CompressLevel.COMPRESS_LEVEL_DEFAULT,
    memLevel: zlib.MemLevel.MEM_LEVEL_DEFAULT,
    strategy: zlib.CompressStrategy.COMPRESS_STRATEGY_DEFAULT
} as zlib.Options)

await zlib.decompressFile('/path/to/dst.zip', '/path/to/out.txt', {
    level: zlib.CompressLevel.COMPRESS_LEVEL_DEFAULT
} as zlib.Options)
```
