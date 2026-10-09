# Contacts

Use this when the blocker is reading or adding contacts.

Contact APIs use `@kit.ContactsKit`. The full surface is large — this doc covers the common patterns.

## Placeholder: full contacts CRUD

The `@kit.ContactsKit` module provides the complete contacts API surface (add, query, update, delete, groups, accounts). Grounded production examples exist in `ark2/ohosapps/applications_contacts/` (82+ files) with full presenter/model/pages patterns. The API surface is too large for a concise single-doc recipe.

Core patterns available:
- `contactManager.addContact(context, contact)`
- `contactManager.queryContacts(context, filter)`
- `contactManager.updateContact(context, contact)`
- `contactManager.deleteContact(context, contactId)`

## Return
- if the first direct fix fails → `35-40-ohos-app-failures.md`
