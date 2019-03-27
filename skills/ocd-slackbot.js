const { spawn } = require('child_process');

const HOME = "/opt/app-root/src";
const OCD_RELEASE = HOME+'/bin/ocd-create-release.sh';
const OCD_DEPLOY = HOME+'/bin/ocd-deploy-config.sh';
const OCD_RHSCL = HOME+'/bin/rhscl-imagechecker.sh';

module.exports = function(controller) {

    /* Collect some very simple runtime stats for use in the uptime/debug command */
    var stats = {
        triggers: 0,
        convos: 0,
    }

    controller.on('heard_trigger', function() {
        stats.triggers++;
    });

    controller.on('conversationStarted', function() {
        stats.convos++;
    });


    controller.hears(['^uptime','^debug'], 'direct_message,direct_mention', function(bot, message) {

        bot.createConversation(message, function(err, convo) {
            if (!err) {
                convo.setVar('uptime', formatUptime(process.uptime()));
                convo.setVar('convos', stats.convos);
                convo.setVar('triggers', stats.triggers);

                convo.say('My main process has been online for {{vars.uptime}}. Since booting, I have heard {{vars.triggers}} triggers, and conducted {{vars.convos}} conversations.');
                convo.activate();
            }
        });

    });

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* Utility function to format uptime */
    function formatUptime(uptime) {
        var unit = 'second';
        if (uptime > 60) {
            uptime = uptime / 60;
            unit = 'minute';
        }
        if (uptime > 60) {
            uptime = uptime / 60;
            unit = 'hour';
        }
        if (uptime != 1) {
            unit = unit + 's';
        }

        uptime = parseInt(uptime) + ' ' + unit;
        return uptime;
    }

    controller.hears([
            '^help', '^--help', '^?'], 
            'direct_message,direct_mention', function(bot, message) {
        bot.replyInThread(message, 'Tell me to `create a release` or `deploy` for more help with commands.')
    });

    controller.hears([
            '^create a release of (.*) from (.*) with tag (.*)',
            '^create a release of (.*) from (.*)',
            '^create a release'], 
            'direct_message,direct_mention', function(bot, message) {
        if (message.match[1]) {
            const APP = message.match[1];
            const SHA = message.match[2];
            var argsArray = [APP, SHA];
            if( message.match[3] ) {
                const TAG = message.match[3];
                argsArray.push(TAG);
            }
            const child = spawn(OCD_RELEASE, argsArray);
            console.log(`${OCD_RELEASE} APP=${APP}; SHA=${SHA}; OCD_RELEASE=${OCD_RELEASE}`);
            
            bot.api.reactions.add({
                timestamp: message.ts,
                channel: message.channel,
                name: 'thumbsup',
            });

            child.on('exit', function (code, signal) {
                if( `${code}` !== "0" ) {
                    var msg =  'ERROR child process exited with ' +
                                `code ${code} and signal ${signal}`;
                    console.log(msg);
                    bot.replyInThread('Success. The new release is '+message+' and it should be built into a container with the same tag in a couple of minutes.', msg);

                }
            });

            child.stdout.on('data', (data) => {
                console.log(`${data}`);
                bot.replyInThread(message, `${data}`);
            });

            child.stderr.on('data', (data) => {
                console.log(`${data}`);
                bot.replyInThread(message, `${data}`);
            });

            
        } else {
            bot.replyInThread(message, 'Tell me to `create a release of $APP from $COMMITISH` or `create a release of $APP from $COMMITISH with tag $TAG` where $COMMITISH can be a commit sha, or bramch. I will then create a github release, with a git tag, that OCD will automatically build container with that code and tag.')
        }
    });

   controller.hears([
            '^deploy (.*) version (.*) to (.*)',
            '^deploy'], 
            'direct_message,direct_mention', function(bot, message) {
        if (message.match[1]) {
            const APP = message.match[1];
            const TAG = message.match[2];
            const ENVIRONMENT = message.match[3];

            var argsArray = [APP, TAG, ENVIRONMENT];
            const child = spawn(OCD_DEPLOY, argsArray);
            console.log(`${OCD_DEPLOY}, APP=${APP}; TAG=${TAG}; ENVIRONMENT=${ENVIRONMENT}`);
            
            bot.api.reactions.add({
                timestamp: message.ts,
                channel: message.channel,
                name: 'thumbsup',
            });

            child.on('exit', function (code, signal) {
                if( `${code}` !== "0" ) {
                    var msg =  'Error child process exited with ' +
                                `code ${code} and signal ${signal}`;
                    console.log(msg);
                    bot.replyInThread(message, msg);
                } else {
                    bot.replyInThread(message, `I have created a PR to promote ${APP} tagged ${TAG} to ${ENVIRONMENT}. Please merge the PR.`);
                }
            });

            child.stdout.on('data', (data) => {
                console.log(`${data}`);
                bot.replyInThread(message, `${data}`);
            });

            child.stderr.on('data', (data) => {
                console.log(`${data}`);
                bot.replyInThread(message, `${data}`);
            });

            
        } else {
            bot.replyInThread(message, 'Tell me to `deploy $APP version $TAG to $ENV`. I will then create a PR in the config repo for changing the container tag running in an environment. When you merge the PR OCD will do the deployment.')
        }
    });

   controller.hears([
            '^do we have the latest rhscl (.*) security patches?'],
            'direct_message,direct_mention', function(bot, message) {
        if (message.match[1]) {
            const IMAGE = message.match[1];
            var argsArray = [IMAGE];
            const child = spawn(OCD_RHSCL, argsArray);
            console.log(`${OCD_RHSCL}, IMAGE=${IMAGE};`);

            bot.api.reactions.add({
                timestamp: message.ts,
                channel: message.channel,
                name: 'thumbsup',
            });

            child.on('exit', function (code, signal) {
                if( `${code}` !== "0" ) {
                    var msg =  'Error child process exited with ' +
                                `code ${code} and signal ${signal}`;
                    console.log(msg);
                    bot.replyInThread(message, msg);
                }
            });

            child.stdout.on('data', (data) => {
                console.log(`${data}`);
                bot.replyPublic(message, `${data}`);
            });

            child.stderr.on('data', (data) => {
                console.log(`${data}`);
                bot.replyInThread(message, `${data}`);
            });
        } 
    });

};
