%%%-------------------------------------------------------------------
%%% @author eokeke
%%% @copyright (C) 2017
%%% @doc
%%% This module is a wrapper around the <code>httpc</code> module. It simplifies the process of sending requests
%%% to the Postmark API.
%%% @end
%%% Created : 19. Jan 2017 10:33 AM
%%%-------------------------------------------------------------------
-module(erlang_postmarkapp_request).
-author("eokeke").

-compile([{parse_transform, lager_transform}]).

-include("erlang_postmarkapp.hrl").

%% API
-export([
    get_default_headers/0,
    request/3,
    request/4,
    http_build_query/1
]).

-type requestMethod() :: delete | get | post | put.
-type queryParamValue() :: string() | integer() | atom() | float() | binary().
-type queryParam() :: {string(), queryParamValue()} | {binary(), queryParamValue()}.
-type queryParams() :: [queryParam()].
-type resultKey() :: headers | body.
-type body() :: {json, list()} | {string, string()}.

%% @doc returns the default request headers
get_default_headers() ->
    [
        {"Accept", ?POSTMARK_CONTENT_TYPE},
        {"X-Postmark-Server-Token", erlang_postmarkapp:get_server_token()}
    ].

%% @doc makes a request to the API appending the <code>Endpoint</code> to the base Url; Body is a proplist.
-spec request(Method::requestMethod(), Endpoint::string(), Body::body()) -> [{resultKey(), list()}] | {error, integer(), term()} | {error, fail, string()}.
request(Method, Endpoint, Body) ->
    case Body of
        {json, Payload} ->
            %% NOTE in contrast to jsx:encode that accepts proplists , jiffy accepts tuple, i.e. {proplists}
            request(Method, Endpoint, jiffy:encode({Payload}), get_default_headers());
        {string, Json} ->
            request(Method, Endpoint, Json, get_default_headers())
    end.

%% @doc makes a request to the API appending the <code>Endpoint</code> to the base Url.
-spec request(Method::requestMethod(), Endpoint::string(), Body::string(), Headers::list()) -> [{resultKey(), list()}] | {error, integer(), term()} | {error, fail, string()}.
request(Method, Endpoint, Payload, Headers) ->
    Url = string:join([?POSTMARK_REST_URL, Endpoint], "/"),
    ContentType = proplists:get_value("content-type", Headers, ?POSTMARK_CONTENT_TYPE),
    lager:info("Request Url: ~p~n", [Url]),
    lager:info("Request Headers: ~p~n", [Headers]),
    lager:info("Request Body: ~p~n", [Payload]),
    case Method of
        get ->
            process_response(httpc:request(get, {Url, Headers}, [], []));
        _ ->
            lager:info("Content-Type: ~p~n", [ContentType]),
            process_response(httpc:request(Method, {Url, Headers, ContentType, Payload}, ?POSTMARK_REQUEST_OPTS, []))
    end.

%% @doc processes the response from the <code>httpc:request/4</code> call, returning an appropriate response
process_response(HttpResponse) ->
    try HttpResponse of
        {ok, {{_HttpVersion, 200, _Phrase}, ResponseHeaders, []}} ->
            %% successfully got a response from the server
            [{headers, ResponseHeaders}, {body, []}];
        {ok, {{_HttpVersion, 200, _Phrase}, ResponseHeaders, Body}} ->
            %% successfully got a response from the server
            lager:info("Response Body: ~p~n", [Body]),
            {Response} = jiffy:decode(list_to_binary(Body)),
            [{headers, ResponseHeaders}, {body, Response}];
        {ok, {{_HttpVersion, _HttpStatus, _Phrase}, ResponseHeaders, Body}} ->
            %% the request did not succeed -- some other http status other than 200
            lager:info("Response Body: ~p~n", [Body]),
            {BodyAsJson} = jiffy:decode(list_to_binary(Body)),
            case erlang_postmarkapp:get_response_data("ErrorCode", BodyAsJson) of
                undefined -> [{headers, ResponseHeaders}, {body, BodyAsJson}];
                ErrorCode ->
                    lager:info("Error Code: ~p~n", [ErrorCode]),
                    ErrorMessage = erlang_postmarkapp:get_response_data("Message", BodyAsJson),
                    {error, ErrorCode, ErrorMessage}
            end;
        {ok, {200, Body}} ->
            lager:info("Response Body: ~p~n", [Body]),
            {Response} = jiffy:decode(list_to_binary(Body)),
            [{headers, []}, {body, Response}];
        {ok, {StatusCode, Body}} ->
            lager:info("Response Body: ~p~n", [Body]),
            {Response} = jiffy:decode(list_to_binary(Body)),
            {error, StatusCode, Response};
        {error, {connect_failed, Reason}} ->
            Message = lists:flatten(["Connection failed error (", Reason, ")"]),
            {error, fail, Message};
        {error, {send_failed, Reason}} ->
            Message = lists:flatten(["Request sending failed error (", Reason, ")"]),
            {error, fail, Message};
        {error, Reason} ->
            lager:info("Response Body: ~p~n", [Reason]),
            {BodyAsJson} = jiffy:decode(list_to_binary(Reason)),
            ErrorMessage = erlang_postmarkapp:get_response_data("Message", BodyAsJson),
            Message = lists:flatten([
                "Postmark API Error (",
                erlang_postmarkapp:get_response_data("ErrorCode", BodyAsJson),
                "): ",
                ErrorMessage
            ]),
            {error, fail, Message}
    catch
        error:badarg -> lager:info("Error:badarg");
        error:Error -> lager:info("Error: ~p~n", [Error])
    end.

%% @doc converts a list of query parameters to a query string
-spec http_build_query(QueryParams::queryParams()) -> string().
http_build_query(QueryParams) when is_list(QueryParams) ->
    ParamsList = lists:map(fun (Param) ->
        case Param of
            {Key, Value} ->
                if
                    is_binary(Value) ->
                        string:join([process_query_key(Key), http_uri:encode(binary_to_list(Value))], "=");
                    is_atom(Value) ->
                        string:join([process_query_key(Key), http_uri:encode(atom_to_list(Value))], "=");
                    true -> string:join([process_query_key(Key), http_uri:encode(Value)], "=")
                end;
            _ -> ""
        end
    end, QueryParams),
    string:join(ParamsList, "&");

%% @spec http_build_query(QueryParams::queryParam()) -> string().
%% @doc converts a list of query parameters to a query string
http_build_query(_) ->
    "".

%% @doc converts a query key to a format that can be used in a URL
process_query_key(Key) ->
    if
        is_list(Key) -> lists:flatten(Key);
        is_atom(Key) -> atom_to_list(Key);
        is_binary(Key) -> binary_to_list(Key);
        true -> Key
    end.