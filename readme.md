# OCD Botkit Chatbot

This is Botkit Chatbot configured for Slack. Botkit runs against many chat solutions and the ocd logic is bash scripts. So it would be easy to send us a PR to have it support many other chat solutions. 

### Install with OCD

There is a demo env repo over at https://github.com/ocd-scm/ocd-demo-env-chatbot with instructions at https://github.com/ocd-scm/ocd-meta/wiki/OpenShift-Online-Pro-(openshift-dot-com)#5-optional-setup-up-the-demo-chatbot

### Adding new chat engines?

The ocd code is bash at `bin/ocd-.*.sh`. The slack specific skills are in `skills/ocd-slackbot.js`. The `package.json` starts `bot.js` so I would guess we would create other versions of `bot.js` and use an env var in the start script within `package.json` to switch between versions of `bot.js`. Thats my guess your mileage may vary. 

#### Set up at slack.com

Once you have setup your Botkit openshift enviroment, the next thing you will want to do is set up a new Slack application via the [Slack developer portal](https://api.slack.com/). This is a multi-step process, but only takes a few minutes. 

* [Read this step-by-step guide](https://botkit.ai/docs/provisioning/slack-events-api.html) to make sure everything is set up. 

* We also have this [handy video walkthrough](https://vimeo.com/311086100) for setting up botkit on openshift.com without using OCD (but obviously once you know slack is setup you would recreate your app using helmfile!)

WARNING: If there is no pvc storage or redis configure each time the pod restarts your bot will forget its slack oauth token. You simply go to its http://xyz/ and and click the login link (or 'back'/'refresh' to get an error page with a link to login) and reauthenticate to your slack workspace to give it a new token. 

### Customize Storage

By default, the starter kit uses a simple file-system based storage mechanism to record information about the teams and users that interact with the bot. While this is fine for development, or use by a single team, most developers will want to customize the code to use a real database system.

There are [Botkit plugins for all the major database systems](https://botkit.ai/readme-middlewares.html#storage-modules) which can be enabled with just a few lines of code.

We have enabled our [Mongo middleware]() for starters in this project. To use your own Mongo database, just fill out `MONGO_URI` in your `.env` file with the appropriate information. For tips on reading and writing to storage, [check out these medium posts](https://botkit.groovehq.com/knowledge_base/categories/build-a-bot)

