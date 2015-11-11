-module(cached).

-include("cached.hrl").

-export([execution/3, execution/4]).

execution(Mod, Func, Args) ->
	execution(Mod, Func, Args, #{}).

execution(Mod, Func, Args, Opts) ->
	case ets:lookup(?TABLE, {Mod, Func, Args}) of
		[] ->
			execute(Mod, Func, Args, Opts);
		[{_, Value, Timestamp}] ->
			check_expiration(Mod, Func, Args, Opts, Value, Timestamp)
	end.

check_expiration(Mod, Func, Args, Opts, Value, Timestamp) ->
	Expiration = get_expiration(Opts),
	Now = erlang:now(),
	case timer:now_diff(Now, Timestamp) of
		Tdiff when Tdiff > Expiration ->
			execute(Mod, Func, Args, Opts);
		_ ->
			Value
	end.

execute(Mod, Func, Args, Opts) ->
	Value = erlang:apply(Mod, Func, Args),
	ets:insert(?TABLE, {{Mod, Func, Args}, Value, erlang:now()}),
	Value.

get_expiration(#{expiration := Expiration} = Opts) when is_integer(Expiration), Expiration > 0 ->
	Expiration * 1000000;
get_expiration(_) ->
	?DEFAULT_EXPIRATION * 1000000.