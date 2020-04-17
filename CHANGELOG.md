# Changelog

## 0.3.0-dev

### Enhancements

- Introduce message handlers for handling process messages in a fashion consistent with action and
  event handlers

### Backwards incompatible changes

- Replace action mounts with action handlers that also cover patching params: this includes the
  rename of `c:action_mount/3` callback to `c:action_handler/3`, `c:before_action_mount/3` callback
  to `c:before_action_handler/3` and `@action_mount true` annotation to `@action_handler true`

## 0.2.0 (2020-04-16)

### Enhancements

- Raise errors with useful messages and examples
- Move mounting and event handling logic out of `__using__` macro

## 0.1.0 (2020-04-14)

Initial version.
