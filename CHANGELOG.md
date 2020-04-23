# Changelog

## 0.4.0-dev

### Enhancements

- Introduce `Phoenix.LiveController.ViewRenderer` that renders live view or component with a view &
  template named after the live module & live action, allowing to consistently hold all templates in
  `lib/my_app_web/templates` directory and to consistently back them with view modules in order to
  accommodate the view logic - even when using live controllers together with regular live views and
  live components

### Backwards incompatible changes

- Call to `use Phoenix.LiveController` no longer provides the rendering behaviour that was moved to
  ViewRenderer so a separate `use Phoenix.LiveController.ViewRenderer` call is needed

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
