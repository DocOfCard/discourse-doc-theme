## 12.0.13

- 修复搜索结果页新标签页设置未稳定生效的问题。
- 改为在搜索结果异步渲染后仅补充 `target`/`rel` 属性。
- 保留 Discourse 原生搜索点击处理与点击统计，不覆盖 `logClick`。

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
