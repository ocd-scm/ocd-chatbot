const { spawn } = require('child_process');

const HOME = "/opt/app-root/src";
const OCD_RELEASE = HOME+'/bin/ocd-create-release.sh';
const OCD_DEPLOY = HOME+'/bin/ocd-deploy-config.sh';

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
            '^create a release of (.*) from commit (.*) with tag (.*)',
            '^create a release of (.*) from commit (.*)',
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
            console.log(`APP=${APP}, SHA=${SHA}, OCD_RELEASE=${OCD_RELEASE}`);
            bot.reply(message, 'Working on it...');
            child.on('exit', function (code, signal) {
                if( `${code}` !== "0" ) {
                    var msg =  'child process exited with ' +
                                `code ${code} and signal ${signal}`;
                    console.log(msg);
                    bot.reply(message, msg);
                }
            });

            child.stdout.on('data', (data) => {
                console.log(`${data}`);
                bot.reply(message, `${data}`);
            });

            child.stderr.on('data', (data) => {
                console.log(`${data}`);
                bot.reply(message, `${data}`);
            });

            
        } else {
            bot.reply(message, 'Tell me to "create a release of $APP from commit $SHA" or "create a release of $APP from commit $SHA" with tag $TAG')
        }
    });

   controller.hears([
            '^deploy (.*) version (.*) to (.*)',
            '^deploy '], 
            'direct_message,direct_mention', function(bot, message) {
        if (message.match[1]) {
            const APP = message.match[1];
            const TAG = message.match[2];
            const ENVIRONMENT = message.match[3];

            var argsArray = [APP, TAG, ENVIRONMENT];
            const child = spawn(OCD_DEPLOY, argsArray);
            console.log(`APP=${APP}, TAG=${TAG}, ENVIRONMENT=${ENVIRONMENT}`);
            bot.reply(message, 'Working on it...');
            child.on('exit', function (code, signal) {
                if( `${code}` !== "0" ) {
                    var msg =  'child process exited with ' +
                                `code ${code} and signal ${signal}`;
                    console.log(msg);
                    bot.reply(message, msg);
                }
            });

            child.stdout.on('data', (data) => {
                console.log(`${data}`);
                bot.reply(message, `${data}`);
            });

            child.stderr.on('data', (data) => {
                console.log(`${data}`);
                bot.reply(message, `${data}`);
            });

            
        } else {
            bot.reply(message, 'Tell me to "create a release of $APP from commit $SHA" or "create a release of $APP from commit $SHA" with tag $TAG')
        }
    });

};
