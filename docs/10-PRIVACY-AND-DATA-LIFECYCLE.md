# ClipPocket privacy and data lifecycle

Clipboard history is private local content. The normal app has no telemetry, account, server or runtime network connection. This describes the required V1 behavior, not an assertion that the retained source is already configured that way.

## Capture exclusions

Respect concealed, transient and auto-generated pasteboard types plus configured ignored types/apps. Retain working baseline filters and add ClipPocket's own marker. Password-manager markers are useful exclusions, not a universal detector for all secrets. Do not claim every password is automatically recognized. Recording Pause and Ignore next copy are user-visible controls.

## Storage and retention

Store only allowed representations within the documented size/budget limits in the user's ClipPocket Application Support directory. No original app-store access/import by default. History is persistent; queue snapshots are ephemeral and released on cancel/complete/quit. Pins are protected within their explicit limits. Clear unpinned and clear all including pins are separate actions.

Ordinary local SwiftData storage is not automatically encrypted by the app. OS account/disk protections are independent; do not make an encryption claim. V1 does not add a homemade crypto layer or cloud backup. Schema upgrades must preserve data and show non-destructive recovery on failure.

## Logs and screens

Log durations, state/error categories and UUIDs/counts only. Remove inherited logs containing history titles or payloads. No notification body should expose copied text on a shared/locked screen by default. Menu bar icon shows state/count, not the last copied text. Local diagnostics export excludes database/payloads. Design/demo screens use fictional examples.

## Clipboard and queue semantics

Canceling a queue clears app snapshots, not the user's system clipboard. Skip does not overwrite clipboard. Activate/Resume does not preload a value. Each explicit paste writes only its own chosen payload; if another app changes the clipboard before dispatch, stop and retain the user's new clipboard. Do not restore stale content over a newer user copy.

## Future AI boundary

No V1 clipboard content is sent to a model or network. Future transformation must be explicit per-item, previewable and separated from originals. It cannot silently turn historical clipboard storage into background upload. The current app does not require AI-provider consent/key screens because no provider is implemented.
