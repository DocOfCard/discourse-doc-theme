import DUserLink from "discourse/ui-kit/d-user-link";

const TopicListExcerptPlugin = <template>
  <div class="gf-last-reply-excerpt">
    {{#if @topic.lastPosterUser}}
      <DUserLink class="gf-last-author" @username={{@topic.lastPosterUser.username}}>
        {{@topic.lastPosterUser.username}}
      </DUserLink>
    {{/if}}
    <a class="gf-last-reply-link" href={{@topic.lastPostUrl}}>
      {{@excerpt}}
    </a>
  </div>
</template>;

export default TopicListExcerptPlugin;
