---
name: no-synthetic-typing-while-user-active
description: "Don't use wtype/synthetic keystrokes to test UI on Brad's live desktop; they land in his focused window"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 2940c003-5f53-4eb6-945a-d8634f8039c9
  modified: 2026-11-17T21:30:16.457Z
---

Don't drive tests with `wtype` (or send_key_state) on Brad's desktop while he's using it. On 2026-11-17 a Spotlight test typed "example.com" into his Claude Code prompt because the menu hadn't opened; he then rejected the next guarded attempt.

**Why:** synthetic keys go to whatever has focus, which is usually the window he is typing in.

**How to apply:** verify UI changes by reading code, logs and screenshots, or by calling the menu/shell IPC directly; if a keystroke test really is needed, ask first or tell Brad to try it himself. See [[omarchy-customizations-made]].
