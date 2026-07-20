import { modifier } from "ember-modifier";
import DUserLink from "discourse/ui-kit/d-user-link";

const excerptCache = new Map();
const excerptQueue = [];
const MAX_CONCURRENCY = 2;
let activeRequests = 0;
let excerptObserver = null;
const excerptTargets = new WeakMap();

function isMobileView() {
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

function runNextRequest() {
  while (activeRequests < MAX_CONCURRENCY && excerptQueue.length > 0) {
    const { task, resolve, reject } = excerptQueue.shift();
    activeRequests += 1;

    Promise.resolve()
      .then(task)
      .then(resolve, reject)
      .finally(() => {
        activeRequests -= 1;
        runNextRequest();
      });
  }
}

function enqueueRequest(task) {
  return new Promise((resolve, reject) => {
    excerptQueue.push({ task, resolve, reject });
    runNextRequest();
  });
}

function postNumberFromUrl(url) {
  const match = String(url || "").match(/\/(\d+)(?:\?.*)?$/);
  const postNumber = Number.parseInt(match?.[1] || "0", 10);
  return Number.isFinite(postNumber) && postNumber > 1 ? postNumber : 0;
}

async function fetchPostByNumber(topicId, postNumber) {
  if (!topicId || !postNumber || postNumber <= 1) {
    return null;
  }

  const response = await fetch(
    `/posts/by_number/${topicId}/${postNumber}.json`,
    { credentials: "same-origin" }
  );

  if (!response.ok) {
    return null;
  }

  const data = await response.json();
  return data?.post || data;
}

function usableReplyPost(post) {
  return (
    post &&
    Number(post.post_number) > 1 &&
    !post.hidden &&
    !post.deleted_at &&
    String(post.cooked || "").trim()
  );
}

function replyUrl(lastPostUrl, postNumber) {
  const url = String(lastPostUrl || "");
  if (!url || !postNumber) {
    return "";
  }
  return url.replace(/\/\d+(?:\?.*)?$/, `/${postNumber}`);
}

async function fetchLastReplyExcerpt(topicId, lastPostUrl) {
  const lastPostNumber = postNumberFromUrl(lastPostUrl);
  if (!topicId || lastPostNumber <= 1) {
    return "";
  }

  const cacheKey = `${topicId}:${lastPostNumber}`;
  if (excerptCache.has(cacheKey)) {
    return excerptCache.get(cacheKey);
  }

  const promise = enqueueRequest(async () => {
    try {
      const post = await fetchPostByNumber(topicId, lastPostNumber);
      if (!usableReplyPost(post)) {
        return "";
      }
      return {
        excerpt: plainTextFromCooked(post.cooked).slice(0, 180),
        postNumber: Number(post.post_number),
      };
    } catch {
      return "";
    }
  });

  excerptCache.set(cacheKey, promise);
  return promise;
}

function loadReplyExcerpt(element, topicId, lastPostUrl) {
  if (!element || element.dataset.gfExcerptLoaded === "true") {
    return;
  }
  if (!topicId || !lastPostUrl) {
    return;
  }

  element.dataset.gfExcerptLoaded = "true";
  fetchLastReplyExcerpt(topicId, lastPostUrl).then((result) => {
    if (!result?.excerpt || !element.isConnected) {
      return;
    }

    element.querySelector(".gf-last-author")?.remove();

    const url = replyUrl(lastPostUrl, result.postNumber);
    if (!url) {
      element.append(document.createTextNode(result.excerpt));
      return;
    }

    const link = document.createElement("a");
    link.className = "gf-last-reply-link";
    link.href = url;
    link.textContent = result.excerpt;
    element.append(link);
  });
}

function ensureObserver() {
  if (excerptObserver || typeof IntersectionObserver === "undefined") {
    return excerptObserver;
  }

  excerptObserver = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) {
          continue;
        }
        excerptObserver.unobserve(entry.target);
        const target = excerptTargets.get(entry.target);
        if (target) {
          loadReplyExcerpt(entry.target, target.topicId, target.lastPostUrl);
        }
      }
    },
    { root: null, rootMargin: "0px", threshold: 0.01 }
  );

  return excerptObserver;
}

const lazyExcerpt = modifier((element, [topic]) => {
  const topicId = Number.parseInt(topic?.id || topic?.get?.("id") || "0", 10);
  const lastPostUrl = topic?.lastPostUrl || topic?.get?.("lastPostUrl") || "";
  const replyCount = Number.parseInt(
    topic?.replyCount || topic?.get?.("replyCount") || "0",
    10
  );

  if (!topicId || !lastPostUrl || replyCount <= 0) {
    return;
  }

  excerptTargets.set(element, { topicId, lastPostUrl });
  const observer = ensureObserver();
  if (observer) {
    observer.observe(element);
  } else {
    loadReplyExcerpt(element, topicId, lastPostUrl);
  }

  return () => {
    excerptObserver?.unobserve(element);
    excerptTargets.delete(element);
  };
});

const TopicListExcerptTheme = <template>
  <div class="gf-last-reply-excerpt" {{lazyExcerpt @topic}}>
    {{#if @topic.lastPosterUser}}
      <DUserLink class="gf-last-author" @username={{@topic.lastPosterUser.username}}>
        {{@topic.lastPosterUser.username}}
      </DUserLink>
    {{/if}}
  </div>
</template>;

export default TopicListExcerptTheme;
