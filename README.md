# Graceful Theme - DocOfCard Modified Edition

[中文说明](#中文说明) | [English](#english)

## 中文说明

这是基于原版 **Graceful Theme** 持续修改和维护的 **DocOfCard 修改版**，并非由 DocOfCard 原创开发。

本修改版在保留原主题轻量、简洁风格的基础上，重点完善了话题列表、桌面端和移动端布局、状态图标、未读标记、摘要显示以及界面细节的一致性。

### 主要改进

- 优化桌面端与移动端话题列表布局
- 改进话题标题、元信息、头像、状态图标及未读标记
- 优化摘要显示、行数控制和响应式表现
- 改进深色与浅色模式下的界面一致性
- 持续适配新版 Discourse

### Discourse Topic Access 插件适配

本主题对 **Discourse Topic Access** 插件提供的话题摘要进行了专项适配。

安装并启用该插件后，主题会优先使用插件返回的权限感知摘要，以保证受限制话题只向有权限的用户展示相应预览内容。插件摘要不可用时，可通过主题设置决定是否由主题生成普通摘要。

推荐版本：

- Discourse Topic Access v1.2.3 或更高版本

相关主题设置：

- `enable_topic_excerpt_fallback`：插件摘要不可用时是否由主题生成摘要
- `topic_excerpt_lines`：话题列表摘要显示行数

### 署名

- 原始主题：Graceful Theme
- 原始主题页面：https://meta.discourse.org/t/a-graceful-theme-for-discourse/93040
- 修改与维护：DocOfCard

原主题许可证及版权要求继续适用。本项目中的“DocOfCard Modified Edition”仅用于标识该修改版本。

---

## English

This package is the **DocOfCard Modified Edition** of the original **Graceful Theme**. It is not an original theme developed by DocOfCard.

The modified edition preserves the lightweight and clean character of the original theme while refining topic lists, desktop and mobile layouts, status icons, unread indicators, excerpts, and visual consistency.

### Main improvements

- Refined desktop and mobile topic-list layouts
- Improved topic titles, metadata, avatars, status icons, and unread indicators
- Enhanced excerpt rendering, line controls, and responsive behavior
- Improved consistency across light and dark color schemes
- Ongoing compatibility updates for recent Discourse releases

### Discourse Topic Access compatibility

This theme includes dedicated compatibility for excerpts supplied by the **Discourse Topic Access** plugin.

When the plugin is installed and enabled, the theme uses its permission-aware topic excerpts so restricted previews are only shown to users with the appropriate access. When no plugin excerpt is available, the theme setting can optionally allow a normal theme-generated fallback excerpt.

Recommended version:

- Discourse Topic Access v1.2.3 or later

Relevant theme settings:

- `enable_topic_excerpt_fallback`: generate a normal excerpt when no plugin excerpt is available
- `topic_excerpt_lines`: number of excerpt lines shown in topic lists

### Credits

- Original theme: Graceful Theme
- Original theme page: https://meta.discourse.org/t/a-graceful-theme-for-discourse/93040
- Modifications and maintenance: DocOfCard

The original theme license and attribution requirements remain applicable. “DocOfCard Modified Edition” identifies this modified distribution only.
