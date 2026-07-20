import { concat } from "@ember/helper";
import { helper } from "@ember/component/helper";
import { htmlSafe } from "@ember/template";
import { modifier } from "ember-modifier";
import themeSettings from "discourse/lib/theme-settings-store";
import { apiInitializer } from "discourse/lib/api";
import lazyHash from "discourse/helpers/lazy-hash";
import topicFeaturedLink from "discourse/helpers/topic-featured-link";
import PluginOutlet from "discourse/components/plugin-outlet";
import NewRepliesDot from "discourse/components/topic-list/new-replies-dot";
import TopicExcerpt from "discourse/components/topic-list/topic-excerpt";
import TopicLink from "discourse/components/topic-list/topic-link";
import UnreadIndicator from "discourse/components/topic-list/unread-indicator";
import TopicPostBadges from "discourse/components/topic-post-badges";
import TopicStatus from "discourse/components/topic-status";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import dCategoryLink from "discourse/ui-kit/helpers/d-category-link";
import dDiscourseTags from "discourse/ui-kit/helpers/d-discourse-tags";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import DUserLink from "discourse/ui-kit/d-user-link";
import { longDate } from "discourse/lib/formatter";
import TopicListExcerptPlugin from "../components/topic-list-excerpt-plugin";
import TopicListExcerptTheme from "../components/topic-list-excerpt-theme";

let gfSiteSettings;

const gfTitleFocus = modifier((element) => {
  const row = element.closest(".topic-list-item");
  const onFocus = () => row?.classList.add("selected");
  const onBlur = () => row?.classList.remove("selected");

  element.addEventListener("focus", onFocus);
  element.addEventListener("blur", onBlur);

  return () => {
    element.removeEventListener("focus", onFocus);
    element.removeEventListener("blur", onBlur);
  };
});

const gfExpandPinned = helper(function ([topic, expandGloballyPinned, expandAllPinned]) {
  if (!topic?.pinned) {
    return false;
  }

  const showExcerpt = gfIsMobileView()
    ? gfSiteSettings?.show_pinned_excerpt_mobile
    : gfSiteSettings?.show_pinned_excerpt_desktop;

  if (!showExcerpt) {
    return false;
  }

  return Boolean(
    (expandGloballyPinned && topic.pinned_globally) || expandAllPinned
  );
});

const gfCategoryColorStyle = helper(function ([category]) {
  const raw =
    category?.color ||
    category?.get?.("color") ||
    category?.bulletColor ||
    category?.get?.("bulletColor") ||
    "";

  const color = String(raw || "").replace(/^#/, "").trim();
  if (!/^[0-9a-fA-F]{3}([0-9a-fA-F]{3})?$/.test(color)) {
    return htmlSafe("");
  }

  return htmlSafe("--gf-category-native-color: #" + color + "; --gf-marker-color: #" + color + ";");
});


function gfReadTopicAccessLevel(topic) {
  const raw =
    topic?.minimumTrustLevel ??
    topic?.minimum_trust_level ??
    topic?.get?.("minimumTrustLevel") ??
    topic?.get?.("minimum_trust_level") ??
    0;

  const level = Number.parseInt(raw, 10);
  return Number.isFinite(level) && level >= 1 && level <= 4 ? level : 0;
}

const gfTopicAccessLevel = helper(function ([topic]) {
  return gfReadTopicAccessLevel(topic);
});

const gfTopicAccessLabel = helper(function ([topic]) {
  const level = gfReadTopicAccessLevel(topic);
  return level === 4 ? "TL4" : level >= 1 && level <= 3 ? `TL${level}+` : "";
});

const gfTopicAccessTitle = helper(function ([topic]) {
  const level = gfReadTopicAccessLevel(topic);
  return level
    ? `阅读门槛：仅限信任等级 ${level} 及以上用户查看`
    : "";
});

const gfLongDate = helper(function ([date]) {
  if (!date) {
    return "";
  }

  return longDate(new Date(date)) || "";
});

function gfShortRelativeTime(dateOrTimestamp) {
  if (!dateOrTimestamp) {
    return "";
  }

  const timestamp =
    typeof dateOrTimestamp === "number"
      ? dateOrTimestamp
      : new Date(dateOrTimestamp).getTime();

  if (!Number.isFinite(timestamp)) {
    return "";
  }

  const diff = Math.max(0, Date.now() - timestamp);
  const minute = 60 * 1000;
  const hour = 60 * minute;
  const day = 24 * hour;

  if (diff < minute) {
    return "<1m";
  }

  if (diff < hour) {
    return `${Math.floor(diff / minute)}m`;
  }

  if (diff < day) {
    return `${Math.floor(diff / hour)}h`;
  }

  return `${Math.floor(diff / day)}d`;
}

const gfShortRelativeDate = helper(function ([date]) {
  return gfShortRelativeTime(date);
});

const gfPostsHeatClass = helper(function ([topic]) {
  const count = Number.parseInt(
    topic?.replyCount || topic?.get?.("replyCount") || 0,
    10
  );

  if (count >= 50) {
    return "gf-posts-heat-high";
  }

  if (count >= 15) {
    return "gf-posts-heat-med";
  }

  if (count >= 10) {
    return "gf-posts-heat-low";
  }

  return "";
});

const gfViewsHeatClass = helper(function ([topic]) {
  const count = Number.parseInt(topic?.views || topic?.get?.("views") || 0, 10);

  if (count >= 1000) {
    return "gf-views-heat-high";
  }

  if (count >= 500) {
    return "gf-views-heat-med";
  }

  if (count >= 100) {
    return "gf-views-heat-low";
  }

  return "";
});

function gfIsMobileView() {
  return (
    document.documentElement.classList.contains("mobile-view") ||
    document.body?.classList.contains("mobile-view") ||
    window.matchMedia?.("(max-width: 767px)")?.matches === true
  );
}

function gfTopicValue(topic, camelKey, snakeKey) {
  return (
    topic?.[camelKey] ??
    topic?.[snakeKey] ??
    topic?.get?.(camelKey) ??
    topic?.get?.(snakeKey)
  );
}

const gfPluginExcerpt = helper(function ([topic]) {
  const value = gfTopicValue(topic, "lastPostExcerpt", "last_post_excerpt");
  return typeof value === "string" ? value.trim() : "";
});

const gfHasPluginExcerpt = helper(function ([topic]) {
  const value = gfTopicValue(topic, "lastPostExcerpt", "last_post_excerpt");
  return typeof value === "string" && value.trim().length > 0;
});

const gfCanThemeFallback = helper(function ([topic]) {
  if (!themeSettings.enable_topic_excerpt_fallback) {
    return false;
  }

  const value = gfTopicValue(
    topic,
    "canThemeExcerptFallback",
    "can_theme_excerpt_fallback"
  );

  // Older or absent plugin: allow the theme fallback. The current plugin
  // explicitly returns false for permission-restricted topics.
  return value !== false;
});

const GracefulTopicCell = <template>
  <td class="main-link topic-list-data gf-topic-cell">
    <div class="gf-topic-row">
      <div class="gf-topic-left">
        <div class="gf-op-avatar">
          {{#if @topic.creator}}
            <DUserLink @username={{@topic.creator.username}} aria-hidden="true" tabindex="-1">
              {{dAvatar @topic.creator imageSize="large"}}
            </DUserLink>
          {{else if @topic.lastPosterUser}}
            <DUserLink @username={{@topic.lastPosterUser.username}} aria-hidden="true" tabindex="-1">
              {{dAvatar @topic.lastPosterUser imageSize="large"}}
            </DUserLink>
          {{/if}}
        </div>

        <div class="gf-topic-copy">
          <PluginOutlet
            @name="topic-list-before-link"
            @outletArgs={{lazyHash topic=@topic}}
          />

          <div class="main-link gf-topic-title">
            <PluginOutlet
              @name="topic-list-before-status"
              @outletArgs={{lazyHash topic=@topic}}
            />
            <TopicStatus @topic={{@topic}} @context="topic-list" />
            <TopicLink
              {{gfTitleFocus}}
              @topic={{@topic}}
              class="title raw-link raw-topic-link"
            />
            {{#if @topic.featured_link}}
              &nbsp;{{topicFeaturedLink @topic}}
            {{/if}}
            <PluginOutlet
              @name="topic-list-after-title"
              @outletArgs={{lazyHash topic=@topic}}
            />
            <UnreadIndicator @topic={{@topic}} />
            {{#if @topic.is_nested_view}}
              {{#if @topic.has_new_replies}}
                <NewRepliesDot @topic={{@topic}} />
              {{/if}}
            {{else}}
              <TopicPostBadges
                @unreadPosts={{@topic.unreadPosts}}
                @unseen={{@topic.unseen}}
                @url={{@topic.lastUnreadUrl}}
              />
            {{/if}}
            <PluginOutlet
              @name="topic-list-after-badges"
              @outletArgs={{lazyHash topic=@topic}}
            />
            {{#if (gfTopicAccessLevel @topic)}}
              <span
                class={{concat "gf-topic-access-badge gf-topic-access-level-" (gfTopicAccessLevel @topic)}}
                title={{gfTopicAccessTitle @topic}}
                aria-label={{gfTopicAccessTitle @topic}}
              >
                <span class="gf-topic-access-icon" aria-hidden="true">{{dIcon "lock"}}</span>
                <span class="gf-topic-access-level">{{gfTopicAccessLabel @topic}}</span>
              </span>
            {{/if}}
            {{#if (gfExpandPinned @topic @expandGloballyPinned @expandAllPinned)}}
              <TopicExcerpt @topic={{@topic}} />
            {{/if}}
            <PluginOutlet
              @name="topic-list-main-link-bottom"
              @outletArgs={{lazyHash
                topic=@topic
                expandPinned=(gfExpandPinned @topic @expandGloballyPinned @expandAllPinned)
              }}
            />
          </div>

          <PluginOutlet
            @name="topic-list-after-main-link"
            @outletArgs={{lazyHash topic=@topic}}
          />

          <div class="gf-topic-meta topic-item-stats" aria-label="topic metadata">
            {{#unless @hideCategory}}
              {{#if @topic.category}}
                {{#unless @topic.isPinnedUncategorized}}
                  <span
                    class="gf-meta-item gf-meta-category-item"
                    title={{concat "类别：" @topic.category.name}}
                    aria-label={{concat "类别：" @topic.category.name}}
                  >
                    <span class="gf-meta-category" style={{gfCategoryColorStyle @topic.category}}>
                      {{dCategoryLink @topic.category}}
                    </span>
                  </span>
                {{/unless}}
              {{/if}}
            {{/unless}}

            {{#if @topic.creator}}
              <span
                class="gf-meta-item gf-meta-author-item"
                title={{concat "发贴人：" @topic.creator.username}}
                aria-label={{concat "发贴人：" @topic.creator.username}}
              >
                <span class="gf-meta-icon" aria-hidden="true">{{dIcon "user"}}</span>
                <DUserLink class="gf-meta-author" @username={{@topic.creator.username}}>
                  {{@topic.creator.username}}
                </DUserLink>
              </span>
            {{/if}}

            {{#if @topic.tags.length}}
              <span class="gf-meta-item gf-meta-tags-item" title="标签" aria-label="标签">
                <span class="gf-meta-icon" aria-hidden="true">{{dIcon "tag"}}</span>
                <span class="gf-meta-tags">{{dDiscourseTags @topic mode="list" tagsForUser=@tagsForUser}}</span>
              </span>
            {{/if}}

            {{#if @topic.createdAt}}
              <span
                class="gf-meta-item gf-meta-created-item"
                title={{concat "发帖时间：" (gfLongDate @topic.createdAt)}}
                aria-label={{concat "发帖时间：" (gfLongDate @topic.createdAt)}}
              >
                <span class="gf-meta-icon" aria-hidden="true">{{dIcon "clock"}}</span>
                <span class="gf-created-at">{{gfShortRelativeDate @topic.createdAt}}</span>
              </span>
            {{/if}}
          </div>
        </div>
      </div>
    </div>
  </td>
</template>;

const GracefulLastPostHeader = <template>
  <th scope="col" class="topic-list-data gf-last-post-header">
    回复
  </th>
</template>;

const GracefulLastPostCell = <template>
  <td class="topic-list-data gf-last-post-cell">
    <div class="gf-desktop-stats">
      <div class="gf-stat-box gf-stat-posts">
        <span class={{concat "gf-stat-number " (gfPostsHeatClass @topic)}}>{{@topic.replyCount}}</span>
        <span class="gf-stat-label">POSTS</span>
      </div>

      <div class="gf-stat-box gf-stat-views">
        <span class={{concat "gf-stat-number " (gfViewsHeatClass @topic)}}>{{@topic.views}}</span>
        <span class="gf-stat-label">VIEWS</span>
      </div>
    </div>

    <div class="gf-last-post-summary" style={{gfCategoryColorStyle @topic.category}}>
      {{#if @topic.replyCount}}
        <div class="gf-last-avatar-inline">
          {{#if @topic.lastPosterUser}}
            <DUserLink @username={{@topic.lastPosterUser.username}} aria-hidden="true" tabindex="-1">
              {{dAvatar @topic.lastPosterUser imageSize="small"}}
            </DUserLink>
          {{/if}}
        </div>

        <div class="gf-last-reply-copy">
          <div class="gf-last-reply-head">
            {{#if @topic.bumpedAt}}
              <a class="gf-last-date" href={{@topic.lastPostUrl}}>
                {{gfShortRelativeDate @topic.bumpedAt}}
              </a>
            {{/if}}
          </div>

          {{#if (gfHasPluginExcerpt @topic)}}
            <TopicListExcerptPlugin
              @topic={{@topic}}
              @excerpt={{gfPluginExcerpt @topic}}
            />
          {{else if (gfCanThemeFallback @topic)}}
            <TopicListExcerptTheme @topic={{@topic}} />
          {{/if}}
        </div>
      {{else}}
        <div class="gf-no-reply">No one has replied</div>
      {{/if}}
    </div>
  </td>
</template>;

export default apiInitializer((api) => {
  gfSiteSettings = api.container.lookup("service:site-settings");

  api.registerValueTransformer(
    "topic-list-item-mobile-layout",
    ({ value }) => false
  );

  api.registerValueTransformer("topic-list-columns", ({ value: columns }) => {
    columns.replace("topic", {
      item: GracefulTopicCell,
    });

    for (const key of ["posters", "replies", "likes", "op-likes", "views"]) {
      columns.delete(key);
    }

    columns.replace("activity", {
      header: GracefulLastPostHeader,
      item: GracefulLastPostCell,
    });
  });
});
