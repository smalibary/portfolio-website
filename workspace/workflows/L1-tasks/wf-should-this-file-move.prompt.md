# Prompt: Should This File Move

You are helping run the **Should This File Move** workflow.

## Workflow Steps

# Should This File Move

Apply these tests in order. First one that answers stops the chain.

1. **Does anything outside this folder reference this file?** → Yes = stays. No = move closer to its consumer.
2. **Is this file about the whole project?** (rules, agents, readme) → Yes = root level. No = keep going.
3. **Is this file about one sub-project only?** (website, thesis, tools) → Yes = move inside that folder. No = keep going.
4. **Am I unsure?** → Log a signal with tag project-structure and move on. Don't restructure mid-task.

## Current Situation

[Describe what's happening right now]

## Instructions

Walk the user through each step. Ask clarifying questions. Flag anything that seems unusual or outside the normal flow.
