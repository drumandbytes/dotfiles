---
name: humanize-comments
description: Strip robotic AI patterns from code comments and replace them with pragmatic, senior-developer comment styles.
---

# Human-Engineer Code Comment Rulebook

Clean up all code comments in the specified file or diff to match the tone, brevity, and focus of a pragmatic senior software engineer.

---

## 1. What to Delete (AI Anti-Patterns)

* **Literal Paraphrasing:** Delete comments that merely translate syntax into plain English.
  * Delete: `// Increment counter by 1` or `// Return true if user is active`
* **Redundant Type/Signature Repetition:** Delete JSDoc/Docstring tags (`@param`, `@returns`, `:type`) when types are already explicit in TypeScript, Python type hints, or modern signatures.
* **File Header Banners:** Strip generic header cards (`/** File: user.ts, Author: Claude, Date: 2026 ... */`).
* **Sycophantic & Educational Filler:** Strip explanations of standard library functions, framework mechanics, or language syntax (e.g., `// Using Array.map to transform items...`).
* **Corporate Passive Voice:** Strip passive phrases like `// This module is responsible for orchestrating...` or `// Care should be taken when modifying...`.

---

## 2. What to Keep & Emulate (Human Developer Patterns)

* **Why over What:** Explain business logic rules, non-obvious domain decisions, hardware quirks, or legacy API constraints.
* **Warning Label Comments:** Retain critical execution-order dependencies or foot-guns (e.g., `// DON'T reorder: must run before DOM hydration`).
* **Bug/Ticket Tracking References:** Keep or request issue references (e.g., `// Fixes safari flexbox bug (PROD-402)`).
* **Pragmatic Shorthand & Tone:** 
  * Use lowercase, sentence fragments, or natural dev shorthand (`// hack: race condition workaround` vs `/* This hack is implemented to prevent a potential race condition */`).
  * Use standard tags (`TODO`, `FIXME`, `HACK`, `NOTE`, `XXX`) without florid explanations.

---

## 3. Concrete Transformation Examples

### Example 1: Trivial Function
AI Style:
/**
 * Helper function that checks if a given user object has an active subscription.
 * @param user The user object to evaluate.
 * @returns True if subscription is active, false otherwise.
 */
function isSubscribed(user: User): boolean {
  // Check if subscription status matches active
  return user.subscriptionStatus === 'active';
}

Human Style:
function isSubscribed(user: User): boolean {
  return user.subscriptionStatus === 'active';
}

### Example 2: Non-Obvious Business Logic & Workarounds
AI Style:
# We need to sleep for 2 seconds here to ensure that the remote database
# syncs properly before we attempt to query the user record again.
time.sleep(2)

Human Style:
# Db sync lag on read-replicas; 2s delay avoids 404 on immediate re-fetch
time.sleep(2)

### Example 3: Edge Case & Guard Clauses
AI Style:
// Iterate through the items array and ensure no null values are present
// before passing the dataset to the analytics engine.
const cleanedItems = items.filter(item => item !== null);

Human Style:
// Mixpanel drops batches if any item in payload is null
const cleanedItems = items.filter(item => item !== null);

---

## 4. Language-Specific Guidelines

* **TypeScript/JavaScript:** Rely on TS types for interface contracts; use block comments (`/* ... */`) only for multi-line architectural notes.
* **Python:** Reserve docstrings (`"""..."""`) strictly for public API interfaces/libraries. Internal functions should use inline `#` comments sparingly.
* **Go / Rust:** Keep doc comments concise and focused on public exports. Avoid writing comments inside function bodies unless handling unsafe code or complex channel synchronization.

---

## Execution Instructions
1. Audit the targeted file or diff against the rules above.
2. Delete every comment that restates syntax or standard language features.
3. Rewrite the remaining comments into direct, active, low-overhead human prose.
4. Return only the sanitized code.
