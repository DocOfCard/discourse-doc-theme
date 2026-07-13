import DUserAvatarFlair from "discourse/ui-kit/d-user-avatar-flair";
import DUserLink from "discourse/ui-kit/d-user-link";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";

<template>
  <div class="topic-poster">
    <DUserLink @user={{@outletArgs.topic.creator}}>
      {{dAvatar @outletArgs.topic.creator imageSize="large"}}
    </DUserLink>
    <DUserAvatarFlair @user={{@outletArgs.topic.creator}} />
  </div>
</template>
