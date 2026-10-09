# Testing ArkTS

This guide shows how to ask the `testing-arkts` skill to add or update tests in an ArkTS project.

## Choose the project test framework first

Inspect the target project's dependency manifests, existing tests, runner
configuration, and build targets before choosing a test framework. Reuse the
project's existing framework and registration pattern; do not introduce
`std.testing` into a project that already uses Hypium or another runner.

## Standalone `ArkTestsuite` fallback

Use `std.testing` only when the target has no existing test framework and the
task is an isolated ArkTS unit suite. In that case, tests are ordinary functions
registered on `arktest.ArkTestsuite`.

```typescript
function parsesInteger(): void {
  arktest.assertEQ(parseValue("42"), 42)
}

function main(): int {
  let suite: arktest.ArkTestsuite = new arktest.ArkTestsuite("parser")
  suite.addTest("parses integer", parsesInteger)
  return suite.run()
}
```

## Standalone framework-native assertions

- `arktest.assertEQ(actual, expected)` for equality
- `arktest.assertTrue(condition)` and `arktest.assertFalse(condition)` for predicates
- `arktest.expectError(action, message)` for an expected error message
- `arktest.expectThrow(action, predicate)` when the error type or fields matter

## Edge Case Test

```typescript
function boundsTest() {
    let str: string = 'test';
    try {
        let x = str[-1];
    } catch (e) {
        arktest.assertTrue(e instanceof StringIndexOutOfBoundsError);
    }
}
```

## Async Test

```typescript
function main(): int {
    let suite = new arktest.ArkTestsuite('AsyncTest');
    suite.addAsyncTest('asyncOp', asyncTest);
    return suite.run();
}

async function asyncTest(): Promise<void> {
    let result = await API.asyncMethod();
    arktest.assertEQ(result, expected);
}
```

## Error Test

### Correct
```typescript
function errorTest() {
    arktest.expectError(() => {
        throw new Error('Specific message');
    }, 'Specific message');
}
```

### Correct 
```typescript
let arr = new Uint16Array(6)
    arktest.expectThrow(() => {
 arr[11] = 1 
}, expectedRangeErrors)
```

### Incorrect
```typescript
function expectYamlError(action: () => void, message: string): void {
    let thrown = false
    let yamlError = false
    try {
        action()
    } catch (e) {
        thrown = true
        yamlError = e instanceof YamlError
    }
    arktest.assertTrue(thrown, message + ' throws')
    arktest.assertTrue(yamlError, message + ' throws YamlError')
}
```

## Keep tests small, direct, and assertive

- Keep each test short and easy to read.
- Make every test assert something meaningful.
- Prefer one clear reason for each test to fail.
- Put the main assertion at the end of the test when possible.
- Include helpful failure messages when the default output would be unclear.

## Use realistic and varied test data

- Avoid placeholder values like `foo`, `bar`, `test`, or `123` unless they are meaningful to the scenario.
- Use irregular, realistic, and varied values.
- Change values across tests so hidden assumptions are more likely to surface.
- Include edge cases, unusual formatting, long values, empty values, and malformed values when relevant.

## Do not share state between tests

- Each test should own the data and environment it needs.
- Avoid shared mutable fixtures.
- Avoid relying on test execution order.
- Prefer local setup inside the test over global setup hooks.
- Clean before a test starts rather than depending on cleanup after a previous test.

## Test public behavior, not implementation details

- Test through public APIs and documented contracts.
- Do not test private or protected methods directly.
- Do not use reflection or other bypasses to reach internal implementation.
- Avoid asserting on internal structure unless it is part of the public contract.
- Do not waste tests on trivial getters, setters, or constructors unless they contain real logic or enforce important rules.

## Write tests that catch bugs, not happy-path demos

- Design tests around real risks, defects, and failure modes.
- Reproduce known bugs with focused regression tests.
- Avoid shallow tests that only demonstrate normal usage.
- Use minimal scaffolding so the actual defect remains visible.
- Do not assert on unimportant details.

## Make tests hostile to weak code

- Run tests in inconvenient environments.
- Use random or generated data where it improves coverage.
- Use parameterized tests for many input combinations.
- Run tests in parallel when the code should be thread-safe.
- Disable network access when internet access is not part of the contract.
- Check behavior under concurrency, resource constraints, and unusual environments when relevant.

## Control slowness and flakiness deliberately

- Separate fast tests from deeper or slower tests.
- Keep fast tests fast enough to run frequently.
- Use timeouts for operations that might hang.
- Avoid arbitrary sleeps.
- Wait for specific events or conditions instead of waiting for a fixed duration.
- Use retries only when the behavior being tested is inherently unreliable and the retry is part of the test strategy.
- Kill or fail tests that run too long.

## Keep fixtures close, generated, or intentional

- Inline small fixtures directly in the test.
- Generate large fixtures at runtime when practical.
- Keep static fixture files only when they are reference material or difficult to generate.
- Use temporary directories and files for runtime artifacts.
- Use ephemeral ports instead of hard-coded ports.
- Do not leave temporary files near production source code.

## Test Coverage

Include tests for:

1. **Basic functionality** - Normal usage, happy path
2. **Edge cases** - Boundary values, empty inputs, special characters
3. **Error handling** - Invalid inputs, type mismatches, index errors
4. **Async behavior** - Concurrent operations, timing (if applicable)
