## 12.0.17

- 修复 discourse-calendar 简体中文活动结束时间出现重复“后”的问题。

## 12.0.14

- Based on the 12.0.12 implementation.
- Fix header quick-search topic links using a capture-phase click handler instead of `api.modifyClass`.
- Set `target="_blank"` before Discourse's native click handler runs, so core click logging and `wantsNewWindow()` behavior are preserved.
- No `MutationObserver`, DOM polling, or component monkey patch is used.

## 12.0.13

- Based directly on 12.0.12.
- Apply the existing per-user new-tab preference to topic links in the header quick-search popup.
- Replace the previous MutationObserver/DOM patch with a component-level `search-menu/results/types` override.
- Preserve Discourse search click logging and native Ctrl/Cmd/middle-click behavior.
- Do not replace the full-page search implementation from 12.0.12.

## 12.0.12

- Preserve Discourse full-page search click analytics when the per-user new-tab preference is enabled.
- Search result links still use native `target="_blank"` navigation without preventing the browser's default action.
- When the preference is disabled, the original Discourse click handler remains unchanged.

## 12.0.11

- Apply the existing per-user new-tab preference to full-page search result topic links.
- Search result links remain native anchors and only receive `target`/`rel` attributes; no global click interception is used.

## 12.0.8

- Topic-list title links now honor the DocOfCard per-user “open topic lists and search results in a new tab” preference.
- This release applies the behavior only to the rebuilt topic list; search results are unchanged for now.

# Changelog

## 12.0.7

- Renamed the package to **Graceful Theme - DocOfCard Modified Edition**.
- Added clear attribution to the original Graceful Theme authors.
- Added DocOfCard modification and maintenance information.
- Replaced the original short theme description with complete English and Simplified Chinese descriptions.
- Added bilingual documentation for features, attribution, and maintenance status.
- Added dedicated compatibility documentation for Discourse Topic Access excerpts.
- Documented the recommended Discourse Topic Access version and excerpt-related theme settings.

## 12.0.5

- Previous DocOfCard modified release.
