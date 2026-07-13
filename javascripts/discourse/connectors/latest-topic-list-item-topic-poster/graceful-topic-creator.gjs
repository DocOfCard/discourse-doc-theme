import Component from "@glimmer/component";
import DUserLink from "discourse/ui-kit/d-user-link";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";

export default class GracefulTopicCreator extends Component {
  get creator() {
    return this.args.outletArgs.topic.creator;
  }

  <template>
    <div class="topic-poster">
      <DUserLink @user={{this.creator}}>
        {{dAvatar this.creator imageSize="large"}}
      </DUserLink>
    </div>
  </template>
}
