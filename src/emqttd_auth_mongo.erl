%%%-----------------------------------------------------------------------------
%%% Copyright (c) 2012-2016 eMQTT.IO, All Rights Reserved.
%%%
%%% Permission is hereby granted, free of charge, to any person obtaining a copy
%%% of this software and associated documentation files (the "Software"), to deal
%%% in the Software without restriction, including without limitation the rights
%%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%%% copies of the Software, and to permit persons to whom the Software is
%%% furnished to do so, subject to the following conditions:
%%%
%%% The above copyright notice and this permission notice shall be included in all
%%% copies or substantial portions of the Software.
%%%
%%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
%%% SOFTWARE.
%%%-----------------------------------------------------------------------------
%%% @doc Authentication with MongoDB.
%%% 
%%% @author @lovecc0923
%%% @author Feng Lee <feng@emqtt.io>
%%%-----------------------------------------------------------------------------
-module(emqttd_auth_mongo).

-behaviour(emqttd_auth_mod).

-include("../../../include/emqttd.hrl").

-export([init/1, check/3, description/0]).

-record(state, {collection, hash_type}).
 
-define(EMPTY(Username), (Username =:= undefined orelse Username =:= <<>>)).

init({Collection, HashType}) ->
  {ok, #state{collection = Collection, hash_type = HashType}}.

check(#mqtt_client{username = Username}, Password, _State)
  when ?EMPTY(Username) orelse ?EMPTY(Password) ->
  {error, undefined};

check(#mqtt_client{username = Username}, Password,
    #state{collection = Collection, hash_type = HashType}) ->
    case emqttd_mongo_client:query(Collection, {<<"username">>, Username}) of
        {ok, [Record]} ->
          check_pass(maps:find(<<"password">>, Record), Password, HashType);
        {ok, []} ->
          {error, notfound};
        {error, Error} ->
            {error, Error}
    end.

check_pass({ok, PassHash}, Password, HashType) ->
  case PassHash =:= hash(HashType, Password) of
    true -> ok;
    false -> {error, password_error}
  end;

check_pass(error, _Password, _HashType) ->
    {error, not_found}.

description() -> "Authentication with MongoDB".

hash(Type, Password) ->
    emqttd_auth_mod:passwd_hash(Type, Password).

