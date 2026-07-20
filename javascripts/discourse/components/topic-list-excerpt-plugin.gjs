const TopicListExcerptPlugin = <template>
  <div class="gf-last-reply-excerpt">
    <a class="gf-last-reply-link" href={{@topic.lastPostUrl}}>
      {{@excerpt}}
    </a>
  </div>
</template>;

export default TopicListExcerptPlugin;
