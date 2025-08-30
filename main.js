const crypto = require("node:crypto");
globalThis.crypto = crypto.webcrypto;
const sqlite = require("node:sqlite");
const axios = require("axios");
axios.defaults.withCredentials = true;
const fs = require("fs");
const ao = require("@permaweb/aoconnect");

const store = new sqlite.DatabaseSync("state.sqlite");
store.exec(`create table if not exists tweets (tweet_id text primary key, tweet, status, score, commentary)`);
const storePutTweet = (tweet) => store.prepare(`insert or replace into tweets (tweet_id, tweet, status) values (?, ?, 0)`).run(tweet.tweet_id, JSON.stringify(tweet));
const storeTweetExists = (tweetId) => store.prepare(`select exists(select * from tweets where tweet_id = ?) as exist`).get(tweetId).exist == 1;

const aowal = JSON.parse(fs.readFileSync("arweave-keyfile-XbOcYUMY8QpPIBSgCI4s9S3IDHoAsYm1m7qv4KWckP0.json"));
const aosig = ao.createSigner(aowal);
// const aopid = "Y8B0Erej-nRufcp1Xhd7_feIgF4Nga1yHmFitOfhPGg";
const aopid = "MMs2Ycxq46Pz3mC2bhz--4XFbPQjiDvR-9g-qKaxg2s";
const aoSendMessage = async (action, message) => await ao.message({
  "process": aopid, "signer": aosig, "data": message, "tags": [{"name": "Action", "value": action}]
});
const getTask = async (tweetId) => {
  const res = JSON.parse((await ao.dryrun({process: aopid, data: "", tags: [{"name": "Action", "value": "GetTaskByTid"}, {"name": "Tid", "value": tweetId}], anchor: "1234"})).Messages[0].Data);
  if( !res.success ){
    throw new Error("failed to get task: " + tweetId);
  }
  return res.task;
};

// (async()=> console.log(await getTask("1")))();

// TODO: read from .env
const tautht0 = "AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA";
const tautht1 = "f6c85c5cadb3337894046a1247d3fb612815bb9f";
const tcsrft0 = "2e09c63544a31bbcef89a777a571758a1b3f431f4a7d54ce6ddc848d92fe0b1070cd2500838cde2aedda72ba9c63641ca838405f02aea5cda6ab61b6ae6db109422e19738e05a2f6c9367b068c7a6182";
const sleep = async (sec) => new Promise(res => setTimeout(res, sec * 1000));
const twGet = async (url) => {
  await sleep(10);
  const res = await axios.get(url, {headers: {"Authorization": "Bearer " + tautht0, "X-Csrf-Token": tcsrft0, "Cookie": "auth_token=" + tautht1 + "; ct0=" + tcsrft0}});
  return res.data;
}
const getTweet = async (tweetId) => {
  const reqv = encodeURIComponent(JSON.stringify({"focalTweetId": tweetId, "referrer": "tweet", "with_rux_injections": false, "rankingMode": "Relevance", "includePromotedContent": true, "withCommunity": true, "withQuickPromoteEligibilityTweetFields": true, "withBirdwatchNotes": true, "withVoice": true}));
  const reqf = encodeURIComponent(JSON.stringify({"rweb_video_screen_enabled": false, "payments_enabled": false, "rweb_xchat_enabled": false, "profile_label_improvements_pcf_label_in_post_enabled": true, "rweb_tipjar_consumption_enabled": true, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "tweet_awards_web_tipping_enabled": false, "responsive_web_grok_show_grok_translated_post": false, "responsive_web_grok_analysis_button_from_backend": true, "creator_subscriptions_quote_tweet_preview_enabled": false, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": true, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": false, "responsive_web_enhance_cards_enabled": false}));
  const reqt = encodeURIComponent(JSON.stringify({"withArticleRichContentState": true, "withArticlePlainText": false, "withGrokAnalyze": false, "withDisallowedReplyControls": false}));
  const turl = `https://x.com/i/api/graphql/oEUIqhz9YZjZVpE5i68Sfg/TweetDetail?variables=${reqv}&features=${reqf}&fieldToggles=${reqt}`;
  const tres = (await twGet(turl)).data.threaded_conversation_with_injections_v2.instructions.find(i => i.type == "TimelineAddEntries").entries.filter(e => e.entryId.startsWith("tweet-")).slice(-1)[0].content.itemContent.tweet_results.result;
  return {
    user_name: tres.core.user_results.result.core.screen_name,
    tweet_id: tres.legacy.id_str,
    user_id: tres.legacy.user_id_str,
    text: tres.legacy.full_text,
  }
}

const main = async () => {
  const reqv = {"timeline_type":"Mentions","count":20};
  const reqf = encodeURIComponent(JSON.stringify({"rweb_video_screen_enabled":false,"payments_enabled":false,"rweb_xchat_enabled":false,"profile_label_improvements_pcf_label_in_post_enabled":true,"rweb_tipjar_consumption_enabled":true,"verified_phone_label_enabled":false,"creator_subscriptions_tweet_preview_api_enabled":true,"responsive_web_graphql_timeline_navigation_enabled":true,"responsive_web_graphql_skip_user_profile_image_extensions_enabled":false,"premium_content_api_read_enabled":false,"communities_web_enable_tweet_community_results_fetch":true,"c9s_tweet_anatomy_moderator_badge_enabled":true,"responsive_web_grok_analyze_button_fetch_trends_enabled":false,"responsive_web_grok_analyze_post_followups_enabled":true,"responsive_web_jetfuel_frame":true,"responsive_web_grok_share_attachment_enabled":true,"articles_preview_enabled":true,"responsive_web_edit_tweet_api_enabled":true,"graphql_is_translatable_rweb_tweet_is_translatable_enabled":true,"view_counts_everywhere_api_enabled":true,"longform_notetweets_consumption_enabled":true,"responsive_web_twitter_article_tweet_consumption_enabled":true,"tweet_awards_web_tipping_enabled":false,"responsive_web_grok_show_grok_translated_post":false,"responsive_web_grok_analysis_button_from_backend":true,"creator_subscriptions_quote_tweet_preview_enabled":false,"freedom_of_speech_not_reach_fetch_enabled":true,"standardized_nudges_misinfo":true,"tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled":true,"longform_notetweets_rich_text_read_enabled":true,"longform_notetweets_inline_media_enabled":true,"responsive_web_grok_image_annotation_enabled":true,"responsive_web_grok_imagine_annotation_enabled":true,"responsive_web_grok_community_note_auto_translation_is_enabled":false,"responsive_web_enhance_cards_enabled":false}));
  while( true ){
    const murl = `https://x.com/i/api/graphql/l6ovGrjBwVobgU4puBCycg/NotificationsTimeline?variables=${encodeURIComponent(JSON.stringify(reqv))}&features=${reqf}`;
    const mres = (await twGet(murl)).data.viewer_v2.user_results.result.notification_timeline.timeline.instructions.find(i => i.type == "TimelineAddEntries").entries;
    reqv["cursor"] = mres.find(e => e.entryId.startsWith("cursor-top-")).content.value;
    const mens = mres.filter(e => e.entryId.startsWith("notification-")).map(e => e.content.itemContent.tweet_results.result.legacy.in_reply_to_status_id_str);
    for( let tweetId of mens ){
      if( storeTweetExists(tweetId) ){
        continue;
      }
      const tweet = await getTweet(tweetId);
      storePutTweet(tweet);
      const aoMid = await aoSendMessage("Infer", JSON.stringify(tweet));
      let wait = 5, retries = 5;
      while( true ){
        if( retries <= 0 ){
          throw new Error("failed to get LLM response");
        }
        await sleep(wait);
        wait *= 2;
        retries -= 1;
        const task = await getTask(tweetId);
        console.log(task);
        if( task.status == "success" ){
          console.log(task.response);
          break
        }
      }
    }
  }
}

main();

// (async () => {
//   console.log(JSON.stringify(await getTweet("1959582094759456849")));
// })();
