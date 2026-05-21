---
id: "wf-should-this-file-move"
layer: "L1"
name: "Should This File Move"
created: "2026-05-21"
last_used: "2026-05-21"
last_reviewed: "2026-05-21"
use_count: "0"
graduation_threshold: "5"
tags:
  - project-structure
  - organization
weight: "checklist"
linked_signals:
  - sig-0009
  - sig-0010
  - sig-0011
---

# Should This File Move

Apply these tests in order. First one that answers stops the chain.

1. **Does anything outside this folder reference this file?** → Yes = stays. No = move closer to its consumer.
2. **Is this file about the whole project?** (rules, agents, readme) → Yes = root level. No = keep going.
3. **Is this file about one sub-project only?** (website, thesis, tools) → Yes = move inside that folder. No = keep going.
4. **Am I unsure?** → Log a signal with tag project-structure and move on. Don't restructure mid-task.