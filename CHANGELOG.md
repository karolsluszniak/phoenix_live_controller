# Changelog

## 0.7.0 (2020-07-10)

### Enhancements

- Introduce `reply/2` for replying to client-side events (feature added in Phoenix.LiveView v0.14)
- Improve errors when replying in non-event handlers
- Improve errors when returning invalid response from a plug or a handler
- Improve errors when passing non-mounted socket e.g. in tests

## 0.6.0 (2020-06-29)

### Enhancements

- Allow to specify action mount options via the `@action_mount_opts` annotation
- Make current URL always available, even during first action handling, for consistency
- Make handler response always be `socket` or `{:noreply, socket}`, even during first action
  handling, for consistency

### Backwards incompatible changes

- Action handlers that have previously returned `{:ok, socket}` or `{:ok, socket, opts}` should now
  return `{:noreply, socket}` and specify opts via the `@action_mount_opts` annotation

## 0.5.0 (2020-06-26)

### Enhancements

- Allow to define plugs with "function call" syntax & arbitrary args for extra flexibility
- Evaluate plug `when` conditions in runtime for extra flexibility
- Introduce new `name` plug variable for accessing handler name for all handler types
- Introduce `get_current_url/1` for accessing the current live URL after the socket is mounted
- Introduce `get_session/1` and `get_session/2` for accessing the session
- Add plug performance benchmark

### Backwards incompatible changes

- Remove the `apply_session` callback in favor of plugs and `get_session` helpers
- Change the plug `message` variable to include an entire message payload and not just the label
- `plug/2` variant with options as second argument is removed in favor of a more flexible (and less
  confusing when mixed with `when`) function call syntax

## 0.4.2 (2020-06-25)

### Bug fixes

- Fix error when no handlers defined in live controller
- Fix duplicate handlers & related warning for handlers with multiple clauses

## 0.4.1 (2020-06-25)

### Bug fixes

- Fix binding to special variables (`action`, `params`...) when plug call is quoted

## 0.4.0 (2020-06-25)

### Enhancements

- Introduce plug system along with `Phoenix.LiveController.plug/2` macro
- Allow to mount with extra options and halt the plug chain by wrapping returned socket in a tuple

### Backwards incompatible changes

- Rename `unless_redirected/2` to `chain/2`
- Remove `c:before_action_handler/3`, `c:before_event_handler/3` and `c:before_message_handler/3`
  - use plugs instead

## 0.3.0 (2020-04-21)

This release pushes LiveController from being a simple action & event router into a more complete
solution for representing most of usual live view logic in a consistent way, including handling
parameter patching and process messages.

### Enhancements

- Introduce *message handlers* for handling process messages in a fashion consistent with action and
  event handlers
- Refactor *action mounts* into *action handlers* responsible both for mounting actions and handling
  parameter patching
- Rewrite some of the docs to facilitate changes in Phoenix 1.5 and LiveView 0.12

### Backwards incompatible changes

- Replace "action mounts" naming with "action handlers" including rename of `c:action_mount/3`
  callback to `c:action_handler/3`, `c:before_action_mount/3` callback to
  `c:before_action_handler/3` and `@action_mount true` annotation to `@action_handler true`; action
  handlers still work exactly the same as before for controllers that don't do parameter patching

## 0.2.0 (2020-04-16)

### Enhancements

- Raise errors with useful messages and examples
- Move mounting and event handling logic out of `__using__` macro

## 0.1.0 (2020-04-14)

Initial version.
