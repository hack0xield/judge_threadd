const crypto = require("node:crypto");
globalThis.crypto = crypto.webcrypto;
const sqlite = require("node:sqlite");
const axios = require("axios");
axios.defaults.withCredentials = true;
const xapi = require("twitter-api-v2");
const fs = require("fs");
const ao = require("@permaweb/aoconnect");

const store = new sqlite.DatabaseSync("state.sqlite");
store.exec(
  `create table if not exists tweets (tweet_id text primary key, tweet)`,
);
const storePutTweet = (tweet) =>
  store
    .prepare(`insert or replace into tweets (tweet_id, tweet) values (?, ?)`)
    .run(tweet.tweet_id, JSON.stringify(tweet));
const storeTweetExists = (tweetId) =>
  store
    .prepare(`select exists(select * from tweets where tweet_id = ?) as result`)
    .get(tweetId).result == 1;

const config = JSON.parse(fs.readFileSync("config.json"));
const aosig = ao.createSigner(config["arweave-keyfile"]);
// const aopid = "Y8B0Erej-nRufcp1Xhd7_feIgF4Nga1yHmFitOfhPGg";
const aopid = "MMs2Ycxq46Pz3mC2bhz--4XFbPQjiDvR-9g-qKaxg2s";
const aoSendMessage = async (to, action, message) =>
  await ao.message({
    process: to,
    signer: aosig,
    data: message,
    tags: [{ name: "Action", value: action }],
  });
const getTask = async (tweetId) => {
  try {
    const response = await ao.dryrun({
      process: aopid,
      data: "",
      tags: [
        { name: "Action", value: "GetTaskByTid" },
        { name: "Tid", value: tweetId },
      ],
      anchor: "1234",
    });
    
    // Check if we got a valid response
    if (!response || !response.Messages || !response.Messages[0] || !response.Messages[0].Data) {
      console.log(`Warning: No valid response from AO for tweet ${tweetId}`);
      return null;
    }
    
    const res = JSON.parse(response.Messages[0].Data);
    if (!res.success) {
      console.log(`Warning: AO returned unsuccessful response for tweet ${tweetId}: ${res.error || 'Unknown error'}`);
      return null;
    }
    return res.task;
  } catch (error) {
    console.log(`Warning: Failed to get task for tweet ${tweetId}: ${error.message}`);
    return null;
  }
};

// (async()=> console.log(await getTask("1")))();

const sleep = async (sec) => new Promise((res) => setTimeout(res, sec * 1000));
const twGet = async (url) => {
  await sleep(10);
  const res = await axios.get(url, {
    headers: {
      Authorization: `Bearer ${config.tautht0}`,
      "X-Csrf-Token": config.tcsrft0,
      Cookie: `auth_token=${config.tautht1}; ct0=${config.tcsrft0}`,
    },
  });
  return res.data;
};
//const twReply = async (tweetId, text) => {
//  const xcl = new xapi.TwitterApi({
//    appKey: config.xapikey,
//    appSecret: config.xapisec,
//    accessToken: config.xapiact,
//    accessSecret: config.xapiacs,
//  });
//  return await xcl.v2.reply(text, tweetId);
//}
//(async()=>{
//  console.log(await twReply("1928413057073463407", "yeah"));
//  process.exit();
//})();
const twPost = async (url, data) => {
  await sleep(10);
  const res = await axios.post(url, data, {
    headers: {
      accept: "*/*",
      "accept-language": "en-US,en;q=0.5",
      authorization:
        "Bearer AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA",
      "content-type": "application/json",
      cookie: `guest_id_marketing=v1%3A175593803586397915; guest_id_ads=v1%3A175593803586397915; guest_id=v1%3A175593803586397915; d_prefs=MjoxLGNvbnNlbnRfdmVyc2lvbjoyLHRleHRfdmVyc2lvbjoxMDAw; __cuid=21c0863a52ae4a569a806ab5de84f9e6; kdt=IpdpXVUcTj7x1FHM2qZmGQCkVpX7CfQpkkrSBl5P; auth_token=2f087d897647e1c0382cc34e967dcf9b7257fe42; ct0=e637e90ff0fb9b3d8870b04c2867d950d30735b8dd004771a30990d2ce8a10eb8f8b1e0275f3e47b41c87babff7700d410f49d3202d7df10ca78f89903a4a6f4c38c387e20183a95bc1e76533a8cbb50; twid=u%3D1512411291268308993; personalization_id="v1_5t3e+t0N/f20OyDv/4vnjQ=="; lang=en; des_opt_in=Y; ph_phc_TXdpocbGVeZVm5VJmAsHTMrCofBQu3e0kN8HGMNGTVW_posthog=%7B%22distinct_id%22%3A%2201990550-72c1-74c0-80be-1e3d0848a6b4%22%2C%22%24sesid%22%3A%5B1756733480208%2C%2201990574-487f-7e20-a6ff-1ee758fa1d3a%22%2C1756733130879%5D%7D; __cf_bm=cjX3o0nRp6xyccOX4SNhsCIkmrj_kQNDOFq6r8tQP5I-1756761153-1.0.1.1-QF4DAZfRreKyXXBawHgYW8gDMR1O7Ss9iWgUPUPlRZwrpAQ_B0YC3TsP8Gi5QuTXr6SpuV.GGdZTc9wLweVA9APjojHSmqfl42qT.Gu1TTo`,
      origin: "https://x.com",
      priority: "u=1, i",
      referer: "https://x.com",
      "sec-ch-ua": `"Not;A=Brand";v="99", "Brave";v="139", "Chromium";v="139"`,
      "sec-ch-ua-mobile": "?0",
      "sec-ch-ua-platform": `"Linux"`,
      "sec-fetch-dest": "empty",
      "sec-fetch-mode": "cors",
      "sec-fetch-site": "same-origin",
      "sec-gpc": "1",
      "user-agent":
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36",
      "x-client-transaction-id":
        "icoRMCE8DfvLcg60U3WQYmuYhYAQujmYhzBws1UxshQ5TCCX3ZbzwvtXiTAnXqpASqYg743SJatLcoBdWYwAAVK8uP/3ig",
      "x-csrf-token":
        "e637e90ff0fb9b3d8870b04c2867d950d30735b8dd004771a30990d2ce8a10eb8f8b1e0275f3e47b41c87babff7700d410f49d3202d7df10ca78f89903a4a6f4c38c387e20183a95bc1e76533a8cbb50",
      "x-twitter-active-user": "yes",
      "x-twitter-auth-type": "OAuth2Session",
      "x-twitter-client-language": "en",
      "x-xp-forwarded-for":
        "ec9376bb56ec3106070b17b99d4f8b9b7a488fd6bd07dab2df21f564d01a8c7dd3166a6d0ffdde6832d365f3f372113706d214a69723f2fca58691ebb3d313cd9ea55da1a9e856f780d3bdd5cb5289b3400eff281d83680f6927d7769e22b30cd9d320b3745f6863b439584fda65315f33c212a2e4bbcfa04e4596237e20a1d1f01da19203905b480f1c0a9de41281a236bfadba08cfd80a1cebbc666726c8ad1de96773db533647891fde7908a45516a46ddbff614b63555d9b65c1b8183812f978dad4046745395db9f66d5430db378238179210e21dc5bddcd7f1f2a2a8168e594fb2cba39de0e9c24755324f8db6",
    },
  });
  return res.data;
};
const replyToTweet = async (tweetId, replyText) => {
  res = await twPost(
    "https://x.com/i/api/graphql/mGOM24dT4fPg08ByvrpP2A/CreateTweet",
    {
      variables: {
        tweet_text: replyText,
        reply: { in_reply_to_tweet_id: tweetId, exclude_reply_user_ids: [] },
        dark_request: false,
        media: { media_entities: [], possibly_sensitive: false },
        semantic_annotation_ids: [],
        disallowed_reply_options: null,
      },
      features: {
        premium_content_api_read_enabled: false,
        communities_web_enable_tweet_community_results_fetch: true,
        c9s_tweet_anatomy_moderator_badge_enabled: true,
        responsive_web_grok_analyze_button_fetch_trends_enabled: false,
        responsive_web_grok_analyze_post_followups_enabled: true,
        responsive_web_jetfuel_frame: true,
        responsive_web_grok_share_attachment_enabled: true,
        responsive_web_edit_tweet_api_enabled: true,
        graphql_is_translatable_rweb_tweet_is_translatable_enabled: true,
        view_counts_everywhere_api_enabled: true,
        longform_notetweets_consumption_enabled: true,
        responsive_web_twitter_article_tweet_consumption_enabled: true,
        tweet_awards_web_tipping_enabled: false,
        responsive_web_grok_show_grok_translated_post: false,
        responsive_web_grok_analysis_button_from_backend: true,
        creator_subscriptions_quote_tweet_preview_enabled: false,
        longform_notetweets_rich_text_read_enabled: true,
        longform_notetweets_inline_media_enabled: true,
        payments_enabled: false,
        rweb_xchat_enabled: false,
        profile_label_improvements_pcf_label_in_post_enabled: true,
        rweb_tipjar_consumption_enabled: true,
        verified_phone_label_enabled: false,
        articles_preview_enabled: true,
        responsive_web_grok_community_note_auto_translation_is_enabled: false,
        responsive_web_graphql_skip_user_profile_image_extensions_enabled: false,
        freedom_of_speech_not_reach_fetch_enabled: true,
        standardized_nudges_misinfo: true,
        tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled: true,
        responsive_web_grok_image_annotation_enabled: true,
        responsive_web_grok_imagine_annotation_enabled: true,
        responsive_web_graphql_timeline_navigation_enabled: true,
        responsive_web_enhance_cards_enabled: false,
      },
      queryId: "mGOM24dT4fPg08ByvrpP2A",
    },
  );
  return res;
};
//(async () => {
//  console.log(
//    JSON.stringify(
//      await replyToTweet("1928413057073463407", "Yeah, all right"),
//    ),
//  );
//  process.exit();
//})();
const getTweet = async (tweetId) => {
  const reqv = encodeURIComponent(
    JSON.stringify({
      focalTweetId: tweetId,
      referrer: "tweet",
      with_rux_injections: false,
      rankingMode: "Relevance",
      includePromotedContent: true,
      withCommunity: true,
      withQuickPromoteEligibilityTweetFields: true,
      withBirdwatchNotes: true,
      withVoice: true,
    }),
  );
  const reqf = encodeURIComponent(
    JSON.stringify({
      rweb_video_screen_enabled: false,
      payments_enabled: false,
      rweb_xchat_enabled: false,
      profile_label_improvements_pcf_label_in_post_enabled: true,
      rweb_tipjar_consumption_enabled: true,
      verified_phone_label_enabled: false,
      creator_subscriptions_tweet_preview_api_enabled: true,
      responsive_web_graphql_timeline_navigation_enabled: true,
      responsive_web_graphql_skip_user_profile_image_extensions_enabled: false,
      premium_content_api_read_enabled: false,
      communities_web_enable_tweet_community_results_fetch: true,
      c9s_tweet_anatomy_moderator_badge_enabled: true,
      responsive_web_grok_analyze_button_fetch_trends_enabled: false,
      responsive_web_grok_analyze_post_followups_enabled: true,
      responsive_web_jetfuel_frame: true,
      responsive_web_grok_share_attachment_enabled: true,
      articles_preview_enabled: true,
      responsive_web_edit_tweet_api_enabled: true,
      graphql_is_translatable_rweb_tweet_is_translatable_enabled: true,
      view_counts_everywhere_api_enabled: true,
      longform_notetweets_consumption_enabled: true,
      responsive_web_twitter_article_tweet_consumption_enabled: true,
      tweet_awards_web_tipping_enabled: false,
      responsive_web_grok_show_grok_translated_post: false,
      responsive_web_grok_analysis_button_from_backend: true,
      creator_subscriptions_quote_tweet_preview_enabled: false,
      freedom_of_speech_not_reach_fetch_enabled: true,
      standardized_nudges_misinfo: true,
      tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled: true,
      longform_notetweets_rich_text_read_enabled: true,
      longform_notetweets_inline_media_enabled: true,
      responsive_web_grok_image_annotation_enabled: true,
      responsive_web_grok_imagine_annotation_enabled: true,
      responsive_web_grok_community_note_auto_translation_is_enabled: false,
      responsive_web_enhance_cards_enabled: false,
    }),
  );
  const reqt = encodeURIComponent(
    JSON.stringify({
      withArticleRichContentState: true,
      withArticlePlainText: false,
      withGrokAnalyze: false,
      withDisallowedReplyControls: false,
    }),
  );
  const turl = `https://x.com/i/api/graphql/oEUIqhz9YZjZVpE5i68Sfg/TweetDetail?variables=${reqv}&features=${reqf}&fieldToggles=${reqt}`;
  const tres = (
    await twGet(turl)
  ).data.threaded_conversation_with_injections_v2.instructions
    .find((i) => i.type == "TimelineAddEntries")
    .entries.filter((e) => e.entryId.startsWith("tweet-"))
    .slice(-1)[0].content.itemContent.tweet_results.result;
  return {
    user_name: tres.core.user_results.result.core.screen_name,
    tweet_id: tres.legacy.id_str,
    user_id: tres.legacy.user_id_str,
    text: tres.legacy.full_text,
  };
};

const judgeOffChain = async (tweet) => {
  const openaires = await axios.post(
    "https://api.openai.com/v1/responses",
    {
      model: "gpt-4o-2024-08-06",
      input: [
        {
          role: "user",
          content: `For this tweet "${tweet.text.replace(/\s+/g, " ")}" try to estimate IQ level of the author and score it from min=60 to max=140. Give a short, 150 max symbols explanation for your estimate.`,
        },
      ],
      text: {
        format: {
          type: "json_schema",
          name: "tweet_reasoning",
          schema: {
            type: "object",
            properties: {
              score: { type: "integer" },
              reasoning: { type: "string" },
            },
            required: ["score", "reasoning"],
            additionalProperties: false,
          },
          strict: true,
        },
      },
    },
    {
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${config.openait}`,
      },
    },
  );
  return JSON.parse(openaires.data.output[0].content[0].text);
};

async function* twitterMentions() {
  const reqv = { timeline_type: "Mentions", count: 20 };
  const reqf = encodeURIComponent(
    JSON.stringify({
      rweb_video_screen_enabled: false,
      payments_enabled: false,
      rweb_xchat_enabled: false,
      profile_label_improvements_pcf_label_in_post_enabled: true,
      rweb_tipjar_consumption_enabled: true,
      verified_phone_label_enabled: false,
      creator_subscriptions_tweet_preview_api_enabled: true,
      responsive_web_graphql_timeline_navigation_enabled: true,
      responsive_web_graphql_skip_user_profile_image_extensions_enabled: false,
      premium_content_api_read_enabled: false,
      communities_web_enable_tweet_community_results_fetch: true,
      c9s_tweet_anatomy_moderator_badge_enabled: true,
      responsive_web_grok_analyze_button_fetch_trends_enabled: false,
      responsive_web_grok_analyze_post_followups_enabled: true,
      responsive_web_jetfuel_frame: true,
      responsive_web_grok_share_attachment_enabled: true,
      articles_preview_enabled: true,
      responsive_web_edit_tweet_api_enabled: true,
      graphql_is_translatable_rweb_tweet_is_translatable_enabled: true,
      view_counts_everywhere_api_enabled: true,
      longform_notetweets_consumption_enabled: true,
      responsive_web_twitter_article_tweet_consumption_enabled: true,
      tweet_awards_web_tipping_enabled: false,
      responsive_web_grok_show_grok_translated_post: false,
      responsive_web_grok_analysis_button_from_backend: true,
      creator_subscriptions_quote_tweet_preview_enabled: false,
      freedom_of_speech_not_reach_fetch_enabled: true,
      standardized_nudges_misinfo: true,
      tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled: true,
      longform_notetweets_rich_text_read_enabled: true,
      longform_notetweets_inline_media_enabled: true,
      responsive_web_grok_image_annotation_enabled: true,
      responsive_web_grok_imagine_annotation_enabled: true,
      responsive_web_grok_community_note_auto_translation_is_enabled: false,
      responsive_web_enhance_cards_enabled: false,
    }),
  );
  while (true) {
    const murl = `https://x.com/i/api/graphql/l6ovGrjBwVobgU4puBCycg/NotificationsTimeline?variables=${encodeURIComponent(JSON.stringify(reqv))}&features=${reqf}`;
    const mres = (
      await twGet(murl)
    ).data.viewer_v2.user_results.result.notification_timeline.timeline.instructions.find(
      (i) => i.type == "TimelineAddEntries",
    ).entries;
    reqv["cursor"] = mres.find((e) =>
      e.entryId.startsWith("cursor-top-"),
    ).content.value;
    const mens = mres
      .filter((e) => e.entryId.startsWith("notification-"))
      .map((e) => {
        let m = e.content.itemContent.tweet_results.result.legacy;
        return {
          root: m.in_reply_to_status_id_str,
          mention: m.id_str,
        };
      });
    for (let men of mens) {
      yield men;
    }
  }
}

//(async()=>{
//  for await (const men of twitterMentions()) {
//    console.log(men);
//  }
//})()

const main = async () => {
  for await (let { root, mention } of twitterMentions()) {
    if (!root || !mention) {
      continue;
    }
    console.log({ root, mention });
    if (storeTweetExists(root)) {
      continue;
    }
    const tweet = await getTweet(root);
    if (tweet.user_id == config.towntid) {
      continue;
    }
    const aoMid = await aoSendMessage(aopid, "Infer", JSON.stringify(tweet));
    let wait = 60;
    let retries = 3;
    let llmres;
    while (true) {
      if (retries <= 0) {
        llmres = await judgeOffChain(tweet);
        llmres.source = "openai";
        break;
      }
      await sleep(wait);
      wait *= 2;
      retries -= 1;
      const task = await getTask(root);
      console.log(task);
      if (task && task.status == "success") {
        llmres = task.response;
        llmres.source = "apus";
        break;
      }
    }
    console.log(llmres);
    tweet.estimate = llmres;
    console.log(
      JSON.stringify(
        await replyToTweet(
          mention,
          ("Score: " + llmres.score + ". " + llmres.reasoning).slice(0, 150),
        ),
      ),
    );
    storePutTweet(tweet);
  }
};

main();

// (async () => {
//   console.log(JSON.stringify(await getTweet("1959582094759456849")));
// })();
