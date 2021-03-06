import { REGEX, STRINGS } from '../shared/constants';
const strings = STRINGS.access;
import { Message, random } from '../shared/common';
import { Slack } from '../logger';

export function applyReceiveMiddleware(controller: botkit.Controller) {
    function onReceiveMessage(bot: botkit.Bot, message: Message) {
        if (message &&
            message.text &&
            message.text.length < 30 &&
            (message.text.match(REGEX.ibizan) || message.channel && message.channel.substring(0, 1) === 'D')) {
            bot.reply(message, `_${random(strings.unknowncommand)} ${random(strings.askforhelp)}_`);
            Slack.addReaction('question', message);
            return;
        }
    }

    function onReceiveUpdateSlackLogger(bot: botkit.Bot, message: Message, next: () => void) {
        Slack.setBot(bot);
        next();
    }

    function onReceiveSetUser(bot: botkit.Bot, message: Message, next: () => void) {
        if (!message.user) {
            next();
            return;
        }
        bot.api.users.info({ user: message.user }, (err, data) => {
            if (!data.ok) {
                next();
                return;
            }
            const { user } = data;
            message.user_obj = user;
            next();
        });
    }

    function onReceiveSetChannel(bot: botkit.Bot, message: Message, next: () => void) {
        if (!message.channel) {
            next();
            return;
        }
        bot.api.channels.info({ channel: message.channel }, (err, data) => {
            if (!data.ok) {
                next();
                return;
            }
            const { channel } = data;
            message.channel_obj = channel;
            next();
        });
    }

    controller.on('message_received', onReceiveMessage);

    controller.middleware.receive.use(onReceiveUpdateSlackLogger);
    controller.middleware.receive.use(onReceiveSetChannel);
    controller.middleware.receive.use(onReceiveSetUser);
}