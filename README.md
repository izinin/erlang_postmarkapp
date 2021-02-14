erlang_postmarkapp
=====

An Erlang library for consuming the Postmark mail service API, inspired by the official Postmark PHP package 
[https://github.com/wildbit/postmark-php](https://github.com/wildbit/postmark-php).

## IMPORTANT NOTICE ##

* JSON dependecy library for this application was replaced and the code implementation has been updated accordingly to support new library API. `jsx` has been changed to `jiffy` because `jsx` does not exist in ejabberd standard installation. In contrast to jsx:encode and decode that accepts proplists , jiffy accepts tuple, i.e. {proplists}
* [Jiffy reference](https://github.com/davisp/jiffy)
---

* [Build](#build)
* [Quickstart](#quickstart)
* [Supported Operations](#supported-operations)
* [Installation](#installation)
* [Data Types](#data-types)
* [Record Types](#record-types)
* [Modules Index](#modules-index)
* [Module Exports Details](#module-exports-details)
* [Simple Usage](#usage)

<a name="build">Build</a>
-----

    $ rebar3 compile
    
<a name="quickstart">Quickstart</a>
--------
To use erlang_postmarkapp from the `console`, simply do this:

    $ ./init.sh
    
This will _build it_ and start the Erlang shell.

<a name="supported-operations">Supported Operations</a>
------------    
This library currently supports _sending emails_, _handling bounces_ and _managing servers_. [**are more functions in the planning?**]

- Sending a single **text** or **html** email [send_email/1](#send_email-1), [send_email/4](#send_email-4), [send_email/11](#send_email-11)
- Sending multiple emails in a batch: [send_email_batch/1](#send_email_batch-1)
- Sending a single email using a template: [send_email_with_template/1](#send_email_with_template-1), [send_email_with_template/10](#send_email_with_template-10)
- Getting delivery stats: [get_delivery_stats/0](#get_delivery_stats-0)
- Querying for bounces: [get_bounces/1](#get_bounces-1)
- Getting a single bounce: [get_bounce/1](#get_bounce-1)
- Getting the dump for a bounce: [get_bounce_dump/1](#get_bounce_dump-1)
- Activating an email that had a bounce: [activate_bounce/1](#activate_bounce-1)
- Getting tags with bounces: [get_bounce_tags/0](#get_bounce_tags-0)
- Getting information about a server: [get_server/0](#get_server-0)
- Editing a server: [edit_server/1](#edit_server-1)

<a name="installation">Installation</a>
--------
Add it to your `rebar.config` like so:    

```erlang
{deps, [
       ...
       {erlang_postmarkapp, "1.*", {git, "https://github.com/emmanix2002/erlang_postmarkapp.git", {branch, "master"}}}
]}.
```

<a name="data-types">Data Types</a>
-------
### <a name="type-deliveryStat">deliveryStat()</a>

<tt>deliveryStat() = {inactive_mails, integer()} | {bounces, [#postmark_bounce_stats{}]}</tt>

### <a name="type-deliveryStatsResponse">deliveryStatsResponse()</a>

<tt>deliveryStatsResponse() = [deliveryStat()] | {error, binary()}</tt>

### <a name="type-bounce">bounce()</a>

<tt>bounce() = #postmark_bounce{}</tt>

### <a name="type-bounces">bounces()</a>

<tt>bounces() = [bounce()]</tt>

### <a name="type-bouncesInfo">bouncesInfo()</a>

<tt>bouncesInfo() = {total, integer()} | {bounces, bounces()}</tt>

### <a name="type-bouncesResponse">bouncesResponse()</a>

<tt>bouncesResponse() = [bouncesInfo()]</tt>

### <a name="type-emailBody">emailBody()</a>

<tt>emailBody() = {text, binary()} | {html, binary()}</tt>

### <a name="type-optionalValue">optionalValue()</a>

<tt>optionalValue() = binary() | undefined</tt>

### <a name="type-optionalListValue">optionalListValue()</a>

<tt>optionalListValue() = list() | undefined</tt>

### <a name="type-postmarkEmail">postmarkEmail()</a>

<tt>postmarkEmail() = #postmark_email{}</tt>

### <a name="type-postmarkEmails">postmarkEmails()</a>

<tt>postmarkEmails() = [postmarkEmail()]</tt>

### <a name="type-sendEmailResponse">sendEmailResponse()</a>

<tt>sendEmailResponse() = {ok, binary()} | {error, binary()}</tt>

### <a name="type-serverColor">serverColor()</a>

<tt>serverColor() = purple | blue | turqoise | green | red | yellow | grey</tt>

### <a name="type-tag">tag()</a>

<tt>tag() = binary()</tt>

### <a name="type-tags">tags()</a>

<tt>tags() = [tag()]</tt>

### <a name="type-trackLinkStatus">trackLinkStatus()</a>

<tt>trackLinkStatus() = none | html_and_text | html_only | text_only</tt>

<a name="record-types">Record Types</a>
---------

### <a name="type-record-postmark_email">#postmark_email{}</a>

<tt>
-record(postmark_email, {
    from                :: binary(),
    to                  :: binary(),
    subject             :: binary(),
    html                :: optionalValue(),
    text                :: optionalValue(),
    tag                 :: optionalValue(),
    track_opens=true    :: boolean(),
    reply_to            :: optionalValue(),
    cc                  :: optionalValue(),
    bcc                 :: optionalValue(),
    track_links         :: trackLinkStatus(),
    template_id         :: optionalValue(),
    template_model      :: optionalListValue(),
    inline_css=true     :: boolean()
})
</tt>

### <a name="type-record-postmark_send_response">#postmark_send_response{}</a>

<tt>
-record(postmark_send_response, {
    message_id  :: binary(),
    error_code  :: integer(),
    message     :: binary()
})
</tt>

### <a name="type-record-postmark_bounce_request">#postmark_bounce_request{}</a>

<tt>
-record(postmark_bounce_request, {
    count=500       :: integer(),
    offset=0        :: integer(),
    bounce_type     :: binary(),
    email           :: binary(),
    inactive        :: boolean(),
    tag             :: binary(),
    message_id      :: binary(),
    from_date       :: binary(),
    to_date         :: binary()
})
</tt>

### <a name="type-record-postmark_bounce_stats">#postmark_bounce_stats{}</a>

<tt>
-record(postmark_bounce_stats, {
    type    :: optionalValue(),
    name    :: binary(),
    count   :: integer()
})
</tt>

### <a name="type-record-postmark_bounce">#postmark_bounce{}</a>

<tt>
-record(postmark_bounce, {
    id              :: integer(),
    type            :: binary(),
    type_code       :: integer(),
    name            :: binary(),
    tag             :: optionalValue(),
    message_id      :: optionalValue(),
    server_id       :: optionalValue(),
    description     :: optionalValue(),
    details         :: optionalValue(),
    email           :: binary(),
    from            :: binary(),
    bounced_at      :: binary(),
    dump_available  :: boolean(),
    inactive        :: boolean(),
    can_activate    :: boolean(),
    subject         :: binary()
})
</tt>

### <a name="type-record-postmark_server">#postmark_server{}</a>

<tt>
-record(postmark_server, {
    id                              :: integer(),
    name                            :: binary(),
    api_tokens=[]                   :: list(),
    server_link                     :: binary(),
    color                           :: serverColor(),
    smtp_api_activated              :: boolean(),
    raw_email_enabled               :: boolean(),
    delivery_hook_url               :: binary(),
    inbound_address                 :: binary(),
    inbound_hook_url                :: binary(),
    bounce_hook_url                 :: binary(),
    include_bounce_content_in_hook  :: boolean(),
    open_hook_url                   :: boolean(),
    post_first_open_only            :: boolean(),
    track_opens                     :: boolean(),
    track_links                     :: trackLinkStatus(),
    inbound_domain                  :: binary(),
    inbound_hash                    :: binary(),
    inbound_spam_threshold          :: integer()
})
</tt>


<a name="modules-index">Modules Index (Exports)</a>
-------
### <a name="module-postmarkapp">erlang_postmarkapp (Email)</a>

[setup/1](#setup-1), 
[setup/2](#setup-2), 
[send_email/1](#send_email-1), 
[send_email/4](#send_email-4), 
[send_email/11](#send_email-11), 
[send_email_with_template/1](#send_email_with_template-1), 
[send_email_with_template/10](#send_email_with_template-10),  
[send_email_batch/1](#send_email_batch-1), 
[get_server_token/0](#get_server_token-0), 
[get_account_token/0](#get_account_token-0), 
[track_links_to_string/1](#track_links_to_string-1)

### <a name="module-postmarkapp_bounces">erlang_postmarkapp_bounces (Bounces)</a>

[activate_bounce/1](#activate_bounce-1), 
[get_delivery_stats/0](#get_delivery_stats-0), 
[get_bounces/1](#get_bounces-1), 
[get_bounce/1](#get_bounce-1), 
[get_bounce_dump/1](#get_bounce_dump-1), 
[get_bounce_tags/0](#get_bounce_tags-0), 

### <a name="module-postmarkapp_server">erlang_postmarkapp_server (Server)</a>

[get_server/0](#get_server-0), 
[edit_server/1](#edit_server-1)


<a name="module-exports-details">Exported Function Details</a>
-----------

### <a name="activate_bounce-1">activate_bounce/1</a>

<div class="spec">

<tt>activate_bounce(BounceId::integer()) -> {ok, bounce()} | {error, binary()}</tt>

</div>

### <a name="get_bounces-1">get_bounces/1</a>

<div class="spec">

<tt>get_bounces(BounceRequestRecord::#postmark_bounce_request{}) -> bouncesResponse() | {error, binary()}</tt>

</div>

### <a name="get_bounce-1">get_bounce/1</a>

<div class="spec">

<tt>get_bounce(BounceId::integer()) -> {ok, bounce()} | {error, binary()}</tt>

</div>

### <a name="get_bounce_dump/1">get_bounce_dump/1</a>

<div class="spec">

<tt>get_bounce_dump(BounceId::integer()) -> {ok, binary()} | {error, binary()}</tt>

</div>

### <a name="get_bounce_tags/0">get_bounce_tags/0</a>

<div class="spec">

<tt>get_bounce_tags() -> {ok, tags()} | {error, binary()}</tt>

</div>

### <a name="get_delivery_stats-0">get_delivery_stats/0</a>

<div class="spec">

<tt>get_delivery_stats() -> deliveryStatsResponse()</tt>

</div>

### <a name="get_server-0">get_server/0</a>

<div class="spec">

<tt>get_server() -> {ok, #postmark_server{}} | {error, binary()}</tt>

</div>

### <a name="edit_server-1">edit_server/1</a>

<div class="spec">

<tt>edit_server(ServerRecord::#postmark_server{}) -> {ok, #postmark_server{}} | {error, binary()}</tt>

</div>

### <a name="setup-1">setup/1</a>

<div class="spec">

<tt>setup(ServerToken::binary()) -> ok</tt>

</div>

### <a name="setup-2">setup/2</a>

<div class="spec">

<tt>setup(ServerToken::binary(), AccountToken::binary()) -> ok</tt>

</div>

### <a name="get_server_token-0">get_server_token/0</a>

<div class="spec">

<tt>get_server_token() -> binary()</tt>

</div>

### <a name="get_account_token-0">get_account_token/0</a>

<div class="spec">

<tt>get_account_token() -> binary()</tt>

</div>

### <a name="send_email-1">send_email/1</a>

<div class="spec">

<tt>send_email(PostmarkEmail::#postmark_email{}) -> sendEmailResponse()</tt>

</div>

### <a name="send_email-4">send_email/4</a>

<div class="spec">

<tt>send_email(From::binary(), To::binary(), Subject::binary(), Body::emailBody()) -> sendEmailResponse()</tt>

</div>

### <a name="send_email-11">send_email/11</a>

<div class="spec">

<tt>send_email(From::binary(), To::binary(), Subject::binary(), HtmlBody::optionalValue(), TextBody::optionalValue(),
        Tag::binary(), TrackOpens::boolean(), ReplyTo::optionalValue(), Cc::optionalValue(), Bcc::optionalValue(),
        TrackLinks::trackLinkStatus()) -> sendEmailResponse()</tt>

</div>

### <a name="send_email_batch-1">send_email_batch/1</a>

<div class="spec">

<tt>send_email_batch(PostmarkEmailList::postmarkEmails()) -> sendEmailResponse()</tt>

</div>

### <a name="send_email_with_template-1">send_email_with_template/1</a>

<div class="spec">

<tt>send_email_with_template(PostmarkEmail::#postmark_email{}) -> sendEmailResponse()</tt>

</div>

### <a name="send_email_with_template-10">send_email_with_template/10</a>

<div class="spec">

<tt>send_email_with_template(From::binary(), To::binary(), TemplateId::binary(), TemplateModel::list(),
        Tag:: optionalValue(), TrackOpens::boolean(), ReplyTo::optionalValue(), Cc::optionalValue(),
        Bcc:: optionalValue(), TrackLinks::trackLinkStatus()) -> sendEmailResponse()</tt>

</div>

### <a name="track_links_to_string-1">track_links_to_string/1</a>

<div class="spec">

<tt>track_links_to_string(TrackLinkStatus::trackLinkStatus()) -> binary()</tt>

</div>

<a name="usage">Usage</a>
-------
Set up erlang_postmarkapp by providing the `Server Token` [and optionally an `Account Token`].  
Before you start making calls, you must call the [setup/1](#setup-1) or [setup/2](#setup-2) functions to initialise 
the library and start all required processes. We recommend putting the call to `setup()` in your `init` function, if you have any.

Here's a simple example of sending a plaintext email:

```erlang
send_text_mail() ->
    ServerToken = "your server token here",
    erlang_postmarkapp:setup(ServerToken),
    Body = {text, "Hello World!"},
    case erlang_postmarkapp:send_email("signature@domain.com", "recipient@example.com", "A good example", Body) of
        {ok, MessageId} -> lager:info("Successfully sent email with MessageID ~p~n", [MessageId]);
        {error, Reason} -> lager:info("Message sending failed because ~p~n", [Reason])
    end.
```

- `setup(ServerToken)`: sets the server token for authenticating with the Postmark API.
- `send_email*()`: these functions allow you to send an email.

**NOTE**: based on the information on the Postman documentation, batch emails are limited to a maximum of 
_**500**_ messages (the library enforces this). For single emails, you can have a maximum of _**50**_ email 
addresses from a combination of all `To, Cc, and Bcc` addresses.
