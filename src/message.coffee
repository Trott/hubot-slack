{ Message, TextMessage } = require.main.require 'hubot'

class ReactionMessage extends Message
  # Represents a message generated by an emoji reaction event
  #
  # type      - A String indicating 'reaction_added' or 'reaction_removed'
  # user      - A User instance that reacted to the item.
  # reaction  - A String identifying the emoji reaction.
  # item_user - A String indicating the user that posted the item.
  # item      - An Object identifying the target message, file, or comment item.
  # event_ts  - A String of the reaction event timestamp.
  constructor: (@type, @user, @reaction, @item_user, @item, @event_ts) ->
    super @user
    @type = @type.replace('reaction_', '')

class SlackTextMessage extends TextMessage

  @MESSAGE_REGEX =  ///
    <              # opening angle bracket
    ([@#!])?       # link type
    ([^>|]+)       # link
    (?:\|          # start of |label (optional)
    ([^>]+)        # label
    )?             # end of label
    >              # closing angle bracket
  ///g

  @MESSAGE_RESERVED_KEYWORDS = ['channel','group','everyone','here']

  # Represents a TextMessage created from the Slack adapter
  #
  # user       - The User object
  # text       - The parsed message text
  # rawText    - The unparsed message text
  # rawMessage - The Slack Message object
  constructor: (@user, text, rawText, @rawMessage, @channel, @robot_name) ->
    @rawText = if rawText? then rawText else @rawMessage.text
    @text = if text? then text else @buildText()
    @thread_ts = @rawMessage.thread_ts if @rawMessage.thread_ts?
    super @user, @text, @rawMessage.ts

  ###*
  # Build the text property, a flat string representation of the contents of this message.
  ###
  buildText: () ->
    # base text
    text = @rawMessage.text

    # flatten any attachments into text
    if @rawMessage.attachments
      attachment_text = @rawMessage.attachments.map(a => a.fallback).join('\n')
      text = text + '\n' + attachment_text

    # replace links
    text = text.replace SlackTextMessage.MESSAGE_REGEX, (m, type, link, label) =>
      switch type
        when '@'
          if label then return "@#{label}"
          # TODO
          # user = @dataStore.getUserById link
          # if user
          #   return "@#{user.name}"
          return m
        when '#'
          if label then return "\##{label}"
          # TODO
          # channel = @dataStore.getChannelById link
          # if channel
          #   return "\##{channel.name}"
          return m
        when '!'
          if link in SlackTextMessage.MESSAGE_RESERVED_KEYWORDS
            return "@#{link}"
          else if label
            return label
          return m
        else
          link = link.replace /^mailto:/, ''
          if label and -1 == link.indexOf label
            return "#{label} (#{link})"
          else
            return link

    text = text.replace /&lt;/g, '<'
    text = text.replace /&gt;/g, '>'
    text = text.replace /&amp;/g, '&'

    if @channel?.is_im
      text = "#{@robot_name} #{text}"     # If this is a DM, pretend it was addressed to us

    @text = text


exports.SlackTextMessage = SlackTextMessage
exports.ReactionMessage = ReactionMessage
