import { concat } from "@ember/helper";
import { helper } from "@ember/component/helper";
import { htmlSafe } from "@ember/template";
import { apiInitializer } from "discourse/lib/api";
import TopicLink from "discourse/components/topic-list/topic-link";
import TopicStatus from "discourse/components/topic-status";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import dCategoryLink from "discourse/ui-kit/helpers/d-category-link";
import dDiscourseTags from "discourse/ui-kit/helpers/d-discourse-tags";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import DUserLink from "discourse/ui-kit/d-user-link";
import { longDate } from "discourse/lib/formatter";

const GF_CLEANUP_KEY = "__gracefulTopicListCleanup";

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

const gfLongDate = helper(function ([date]) {
  if (!date) {
    return "";
  }

  return longDate(new Date(date)) || "";
});

function gfIsMobileView() {
  return (
    document.documentElement.classList.contains("mobile-view") ||
    document.body?.classList.contains("mobile-view") ||
    window.matchMedia?.("(max-width: 767px)")?.matches === true
  );
}

function plainTextFromCooked(cooked) {
  const wrapper = document.createElement("div");
  wrapper.innerHTML = cooked || "";
  return (wrapper.textContent || "").replace(/\s+/g, " ").trim();
}

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
    return Math.floor(diff / minute) + "m";
  }

  if (diff < day) {
    return Math.floor(diff / hour) + "h";
  }

  return Math.floor(diff / day) + "d";
}

const gfShortRelativeDate = helper(function ([date]) {
  return gfShortRelativeTime(date);
});

const gfOriginalPoster = helper(function ([topic]) {
  const posters = topic?.posters || topic?.get?.("posters") || [];
  const firstPoster = posters?.[0];
  const firstPosterUser =
    firstPoster?.user ||
    firstPoster?.get?.("user") ||
    firstPoster?.poster ||
    firstPoster?.get?.("poster") ||
    (firstPoster?.username ? firstPoster : null);

  return firstPosterUser || topic?.creator || topic?.get?.("creator") || null;
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

const desktopExcerptCache = new Map();

function gfPostNumberFromUrl(url) {
  const match = String(url || "").match(/\/(\d+)(?:\?.*)?$/);
  const postNumber = Number.parseInt(match?.[1] || "0", 10);

  return Number.isFinite(postNumber) && postNumber > 1 ? postNumber : 0;
}

async function fetchPostByNumber(topicId, postNumber) {
  if (!topicId || !postNumber || postNumber <= 1) {
    return null;
  }

  const response = await fetch(
    "/posts/by_number/" + topicId + "/" + postNumber + ".json",
    { credentials: "same-origin" }
  );

  if (!response.ok) {
    return null;
  }

  const data = await response.json();
  return data?.post || data;
}

function gfUsableReplyPost(post) {
  return (
    post &&
    Number(post.post_number) > 1 &&
    !post.hidden &&
    !post.deleted_at &&
    String(post.cooked || "").trim()
  );
}

function gfReplyUrl(lastPostUrl, postNumber) {
  const url = String(lastPostUrl || "");

  if (!url || !postNumber) {
    return "";
  }

  return url.replace(/\/\d+(?:\?.*)?$/, "/" + postNumber);
}

async function fetchLastReplyExcerpt(topicId, lastPostUrl, replies) {
  const lastPostNumber = gfPostNumberFromUrl(lastPostUrl);
  const fallbackPostNumber = Number.parseInt(replies || "0", 10) + 1;
  const highestPostNumber = Math.max(lastPostNumber, fallbackPostNumber);

  if (!topicId || highestPostNumber <= 1) {
    return "";
  }

  const cacheKey = topicId + ":" + highestPostNumber;

  if (desktopExcerptCache.has(cacheKey)) {
    return desktopExcerptCache.get(cacheKey);
  }

  const promise = (async () => {
    for (let postNumber = highestPostNumber; postNumber >= 2; postNumber--) {
      try {
        const post = await fetchPostByNumber(topicId, postNumber);

        if (gfUsableReplyPost(post)) {
          return {
            excerpt: plainTextFromCooked(post.cooked).slice(0, 180),
            postNumber: Number(post.post_number),
          };
        }
      } catch {
        // Keep searching older reply numbers. A deleted or hidden post can fail here.
      }
    }

    return "";
  })();

  desktopExcerptCache.set(cacheKey, promise);
  return promise;
}

function patchDesktopReplyExcerpts() {
  if (gfIsMobileView()) {
    return;
  }

  document
    .querySelectorAll(".topic-list tbody.topic-list-body > tr.topic-list-item")
    .forEach((row) => {
      const topicId = Number.parseInt(row.dataset.topicId || "0", 10);
      const excerptNode = row.querySelector(".gf-last-reply-excerpt");
      const repliesText = row.querySelector(".gf-stat-posts .gf-stat-number")?.textContent || "0";
      const replies = Number.parseInt(repliesText.trim(), 10) || 0;

      if (!topicId || !excerptNode || replies <= 0 || excerptNode.dataset.gfExcerptLoaded === "true") {
        return;
      }

      const lastPostUrl = row.querySelector(".gf-last-date")?.getAttribute("href");

      excerptNode.dataset.gfExcerptLoaded = "true";
      fetchLastReplyExcerpt(topicId, lastPostUrl, replies).then((result) => {
        if (!result?.excerpt) {
          return;
        }

        const replyUrl = gfReplyUrl(lastPostUrl, result.postNumber);

        if (!replyUrl) {
          excerptNode.textContent = result.excerpt;
          return;
        }

        const link = document.createElement("a");
        link.className = "gf-last-reply-link";
        link.href = replyUrl;
        link.textContent = result.excerpt;

        excerptNode.replaceChildren(link);
      });
    });
}

function resetDesktopReplyExcerptMarkers() {
  document.querySelectorAll(".gf-last-reply-excerpt[data-gf-excerpt-loaded]").forEach((node) => {
    delete node.dataset.gfExcerptLoaded;
  });
}


const GracefulTopicCell = <template>
  <td class="main-link topic-list-data gf-topic-cell">
    <div class="gf-topic-row">
      <div class="gf-topic-left">
        <div class="pull-left gf-op-avatar">
          {{#let (gfOriginalPoster @topic) as |originalPoster|}}
            {{#if originalPoster}}
              <DUserLink @username={{originalPoster.username}} aria-hidden="true" tabindex="-1">
                {{dAvatar originalPoster imageSize="large"}}
              </DUserLink>
            {{/if}}
          {{/let}}
        </div>

        <div class="topic-item-metadata right gf-topic-copy">
          <div class="main-link gf-topic-title">
            <span class="topic-statuses"><TopicStatus @topic={{@topic}} @context="topic-list" /></span>
            <TopicLink @topic={{@topic}} class="title raw-link raw-topic-link" />
          </div>

          <div class="gf-topic-meta topic-item-stats clearfix" aria-label="topic metadata">
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

            {{#let (gfOriginalPoster @topic) as |originalPoster|}}
              {{#if originalPoster}}
                <span
                  class="gf-meta-item gf-meta-author-item"
                  title={{concat "发贴人：" originalPoster.username}}
                  aria-label={{concat "发贴人：" originalPoster.username}}
                >
                  <span class="gf-meta-icon" aria-hidden="true">{{dIcon "user"}}</span>
                  <DUserLink class="gf-meta-author" @username={{originalPoster.username}}>
                    {{originalPoster.username}}
                  </DUserLink>
                </span>
              {{/if}}
            {{/let}}

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

          <div class="gf-last-reply-excerpt">
            {{#if @topic.lastPosterUser}}
              <DUserLink class="gf-last-author" @username={{@topic.lastPosterUser.username}}>
                {{@topic.lastPosterUser.username}}
              </DUserLink>
            {{/if}}
          </div>
        </div>
      {{else}}
        <div class="gf-no-reply">No one has replied</div>
      {{/if}}
    </div>
  </td>
</template>;

export default apiInitializer((api) => {
  globalThis[GF_CLEANUP_KEY]?.();

  let patchTimer = null;
  let patchFrame = null;
  let patchFollowupTimer = null;
  const cleanupCallbacks = [];

  const runTopicListPatches = () => {
    patchFrame = null;

    if (!gfIsMobileView()) {
      patchDesktopReplyExcerpts();
    }
  };

  const scheduleTopicListPatches = ({ resetExcerpts = false } = {}) => {
    if (resetExcerpts) {
      resetDesktopReplyExcerptMarkers();
    }

    clearTimeout(patchTimer);
    clearTimeout(patchFollowupTimer);

    if (patchFrame) {
      cancelAnimationFrame(patchFrame);
      patchFrame = null;
    }

    patchTimer = setTimeout(() => {
      patchFrame = requestAnimationFrame(() => {
        runTopicListPatches();
        patchFollowupTimer = setTimeout(runTopicListPatches, 250);
      });
    }, 30);
  };

  const htmlClassObserver = new MutationObserver(() =>
    scheduleTopicListPatches({ resetExcerpts: true })
  );
  htmlClassObserver.observe(document.documentElement, {
    attributes: true,
    attributeFilter: ["class"],
  });
  cleanupCallbacks.push(() => htmlClassObserver.disconnect());

  const viewportHandler = () => scheduleTopicListPatches({ resetExcerpts: true });
  window.addEventListener("resize", viewportHandler, { passive: true });
  window.addEventListener("orientationchange", viewportHandler, { passive: true });
  window.visualViewport?.addEventListener("resize", viewportHandler, { passive: true });
  cleanupCallbacks.push(() => {
    window.removeEventListener("resize", viewportHandler);
    window.removeEventListener("orientationchange", viewportHandler);
    window.visualViewport?.removeEventListener("resize", viewportHandler);
  });

  globalThis[GF_CLEANUP_KEY] = () => {
    clearTimeout(patchTimer);
    clearTimeout(patchFollowupTimer);

    if (patchFrame) {
      cancelAnimationFrame(patchFrame);
      patchFrame = null;
    }

    cleanupCallbacks.splice(0).forEach((callback) => callback());
    delete globalThis[GF_CLEANUP_KEY];
  };

  api.onPageChange(() => {
    scheduleTopicListPatches({ resetExcerpts: true });
  });

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

    requestAnimationFrame(() => {
      scheduleTopicListPatches({ resetExcerpts: true });
    });
  });

  scheduleTopicListPatches({ resetExcerpts: true });
});