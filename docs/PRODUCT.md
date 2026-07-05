# TACT — Product Vision

> Read this before writing any code. Every architectural and product decision must be traceable back to this document.

## What TACT Is

TACT is a **daily communication keyboard**. Its purpose is to help people communicate better while typing.

The keyboard must feel almost identical to Gboard in speed and comfort. The user should forget that AI even exists — AI is only an optional tool. **Typing experience is the product. Helping is secondary.**

## Mission

Help users write:

- faster
- more accurately
- more politely
- with fewer mistakes

**without interrupting typing.**

## Core Idea

Every feature must answer one question:

> **"Does this make typing better?"**

If the answer is no — do not build it. This is the rule that keeps TACT focused.

## Product Principles

The keyboard must **never**:

- block typing
- slow typing
- surprise the user
- automatically rewrite messages
- spam suggestions
- interrupt conversations

The keyboard should quietly help.

## How TACT Behaves

### Normal state
The suggestion bar behaves like Gboard — only normal word suggestions.

### Spell mistake (completed word)
`📝 Mistake found` → `[Fix]`
AI runs only after the user taps **Fix**.

### Anti-Toxic (completed word recognized as toxic)
`⚠ Possible conflict` → `[Soften]`
No automatic changes.

### Anti-Mat (profanity detected)
`⚠ Profanity detected` → `[Remove]`
No automatic censorship. The user decides.

### Improve
If the current message is ≳30 characters **and** has no spelling mistakes, toxicity, or profanity:
`✨ Improve text` → `[Improve]`

### Shortcuts
- Built-in: `thx` → `Thanks`
- User: `addr` → full home address
Everything local.

## Offline First

These must work **without AI, without network**:

- Spell check
- Profanity detection
- Toxicity detection
- Shortcuts
- Suggestions

## AI

AI is expensive. AI is slower. **AI must never run automatically.**

AI runs only after an explicit user tap on one of:

- **Fix**
- **Improve**
- **Soften**

## Target Users

Everyday users, students, office workers, parents, teenagers — anyone who types every day.

---

## NON-GOALS

TACT does **not** build features that do not directly improve typing.

- ❌ AI Chat
- ❌ AI Assistant
- ❌ Image Generation
- ❌ Email Client
- ❌ Translation Platform
- ❌ Social Features
- ❌ Community
- ❌ Themes Marketplace
- ❌ Plugin System

Focus entirely on making the typing experience exceptional.

## Success Metric

The project succeeds when users think:

> **"I don't want to switch back to Gboard."**

Not because TACT has more features. Because typing simply feels better.
