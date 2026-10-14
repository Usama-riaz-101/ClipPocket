# ClipPocket future AI extension boundary

Future AI is a possibility, not a V1 task. Deliver the working clipboard/queue utility first. No AI provider, MCP tool, API credentials, server, embedding index or AI buttons/placeholders in V1.

## Small architectural seam

Keep text retrieval, optional transformation and paste execution separate. An internal transformation contract can accept an explicit immutable text snapshot and return a proposed derived result. In V1 the identity implementation returns unchanged text. This separation also supports non-AI clean-formatting utilities; do not build a plugin framework in anticipation of unknown features.

Original history content is never destructively rewritten by a future transform. A derived snippet needs its own identifier and optional original-reference link. Queue contents are snapshots; a transformed value would enter only through explicit user selection and review. Cancellation/source-version checks must reject stale transformation results.

## Possible later capabilities

User-triggered grammar cleanup, Roman Urdu/Hindi conversion, translation, tone adjustment, code explanation or summarization of one chosen snippet. Each requires a separate product decision, provider/local-model evaluation, latency/cost measurements and explicit content-handling choices. None is authorized or implemented by this pack.

Future service credentials belong in Keychain, never history storage. Default clipboard history remains local. Do not reserve a remote backend schema now, download models, add a paid dependency or make the V1 UI advertise unfinished features.
