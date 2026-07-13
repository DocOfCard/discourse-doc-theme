import { apiInitializer } from "discourse/lib/api";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import DUserLink from "discourse/ui-kit/d-user-link";

const GracefulOriginalPoster = <template>
  {{#if @outletArgs.topic.creator}}
    <div class="topic-poster">
      <DUserLink
        @username={{@outletArgs.topic.creator.username}}
        data-user-card={{@outletArgs.topic.creator.username}}
      >
        {{dAvatar @outletArgs.topic.creator imageSize="large"}}
      </DUserLink>
    </div>
  {{/if}}
</template>;

export default apiInitializer("1.0.0", (api) => {
  api.renderInOutlet(
    "latest-topic-list-item-topic-poster",
    GracefulOriginalPoster
  );

  const key = "__gfNativeMobileTopicMetaExperiment";
  const previous = window[key];

  if (previous?.cleanup) {
    previous.cleanup();
  }

  const iconHtml = (id) =>
    `<span class="gf-native-meta-icon" aria-hidden="true"><svg class="fa d-icon d-icon-${id} svg-icon svg-string" width="1em" height="1em" aria-hidden="true"><use href="#${id}"></use></svg></span>`;

  const shortRelativeTime = (timestamp) => {
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
  };

  const restoreNativeTime = (activity) => {
    if (!activity) {
      return null;
    }

    if (activity.dataset.gfOriginalHtml && activity.querySelector(".gf-mobile-time-text")) {
      activity.innerHTML = activity.dataset.gfOriginalHtml;
    }

    activity.classList.add("gf-native-meta-time");
    activity.classList.remove("gf-mobile-meta-time");

    const relativeDate = activity.querySelector(".relative-date[data-time]");
    const timestamp = Number.parseInt(relativeDate?.dataset.time || "", 10);
    const shortText = shortRelativeTime(timestamp);

    if (relativeDate && shortText) {
      const replacement = relativeDate.cloneNode(false);
      replacement.textContent = shortText;
      relativeDate.replaceWith(replacement);
    }

    return activity;
  };

  const buildReplyMeta = (pullRight) => {
    const nativePosts = pullRight?.querySelector(".num.posts");
    if (!nativePosts) {
      return null;
    }

    let replyMeta = pullRight.querySelector(".gf-native-meta-replies");
    if (!replyMeta) {
      replyMeta = document.createElement("span");
      replyMeta.className = "gf-native-meta-replies";
      replyMeta.innerHTML = iconHtml("far-comment");
      replyMeta.append(nativePosts);
    } else if (!replyMeta.contains(nativePosts)) {
      replyMeta.append(nativePosts);
    }

    return replyMeta;
  };

  const buildTagMeta = (stats) => {
    const tags = stats?.querySelector(".topic-item-stats__category-tags .discourse-tags");
    if (!tags) {
      return;
    }

    const existingIcon = tags.previousElementSibling;
    if (existingIcon?.classList.contains("gf-native-tag-icon")) {
      return;
    }

    const tagIcon = document.createElement("span");
    tagIcon.className = "gf-native-meta-icon gf-native-tag-icon";
    tagIcon.setAttribute("aria-hidden", "true");
    tagIcon.innerHTML = `<svg class="fa d-icon d-icon-tag svg-icon svg-string" width="1em" height="1em" aria-hidden="true"><use href="#tag"></use></svg>`;
    tags.before(tagIcon);
  };

  const patch = () => {
    if (!document.documentElement.classList.contains("mobile-view")) {
      return;
    }

    document
      .querySelectorAll(".topic-list tbody.topic-list-body > tr.topic-list-item")
      .forEach((row) => {
        const stats = row.querySelector(".topic-item-metadata.right > .topic-item-stats");
        const pullRight = row.querySelector(".topic-item-metadata.right > .pull-right");

        if (!stats || !pullRight) {
          return;
        }

        row.querySelector(".gf-mobile-meta-status")?.remove();
        row.querySelector(".gf-mobile-replies-badge")?.remove();
        row.querySelector(".gf-mobile-views-badge")?.remove();

        const time = restoreNativeTime(stats.querySelector(".activity, .gf-mobile-meta-time"));
        const replies = buildReplyMeta(pullRight);
        buildTagMeta(stats);

        if (replies && replies.parentElement !== stats) {
          stats.append(replies);
        }

        if (time && time.parentElement !== stats) {
          stats.append(time);
        }
      });
  };

  let timer = null;
  let frame = null;

  const schedule = () => {
    clearTimeout(timer);
    if (frame) {
      cancelAnimationFrame(frame);
    }

    frame = requestAnimationFrame(() => {
      patch();
      timer = setTimeout(patch, 250);
    });
  };

  const observer = new MutationObserver(schedule);
  observer.observe(document.body, { childList: true, subtree: true });

  window.addEventListener("resize", schedule, { passive: true });
  window.addEventListener("orientationchange", schedule, { passive: true });
  window.visualViewport?.addEventListener("resize", schedule, { passive: true });

  window[key] = {
    schedule,
    cleanup() {
      clearTimeout(timer);
      if (frame) {
        cancelAnimationFrame(frame);
      }
      observer.disconnect();
      window.removeEventListener("resize", schedule);
      window.removeEventListener("orientationchange", schedule);
      window.visualViewport?.removeEventListener("resize", schedule);
    },
  };

  schedule();

  api.onPageChange(() => {
    window.requestAnimationFrame(() => window.__gfNativeMobileTopicMetaExperiment?.schedule?.());
  });
});
