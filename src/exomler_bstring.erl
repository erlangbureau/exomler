-module(exomler_bstring).

%% API
-export([split/2, split_global/2]).
-export([trim/1, trim_left/1, trim_right/1]).
-export([to_lower/1, to_upper/1]).

-define(IS_BLANK(Blank),
    Blank == $\s;
    Blank == $\t;
    Blank == $\n;
    Blank == $\r
).

-include("unicode.hrl").

-type binary_string() :: unicode:unicode_binary().

%% API
-spec split(BinString, Pattern) -> {PartBeforePattern, PartAfterPattern} when
        BinString :: binary_string(),
        Pattern :: binary_string(),
        PartBeforePattern :: binary_string(),
        PartAfterPattern :: binary_string().
split(BinString, Pattern) ->
    case binary:match(BinString, Pattern) of
        {A,B} ->
            <<Before:A/binary, _:B/binary, After/binary>> = BinString,
            {Before, After};
        nomatch ->
            {BinString, <<>>}
    end.

-spec split_global(BinString, Pattern) -> [BinStringPart] when
        BinString :: binary_string(),
        Pattern :: binary_string(),
        BinStringPart :: binary_string().
split_global(BinString, Pattern) ->
    split_global(BinString, Pattern, []).

split_global(BinString, Pattern, Acc) ->
    case binary:match(BinString, Pattern) of
        {A,B} ->
            <<Before:A/binary, _:B/binary, After/binary>> = BinString,
            split_global(After, Pattern, [Before|Acc]);
        nomatch ->
            lists:reverse([BinString|Acc])
    end.

-spec trim(BinString1) -> BinString2 when
        BinString1 :: binary_string(),
        BinString2 :: binary_string().
trim(BinString) ->
    trim_right(trim_left(BinString)).

-spec trim_left(BinString1) -> BinString2 when
        BinString1 :: binary_string(),
        BinString2 :: binary_string().
trim_left(<<$\s, BinString/binary>>) ->
    trim_left(BinString);
trim_left(<<$\t, BinString/binary>>) ->
    trim_left(BinString);
trim_left(<<$\n, BinString/binary>>) ->
    trim_left(BinString);
trim_left(<<$\r, BinString/binary>>) ->
    trim_left(BinString);
trim_left(BinString) ->
    BinString.

-spec trim_right(BinString1) -> BinString2 when
        BinString1 :: binary_string(),
        BinString2 :: binary_string().
trim_right(<<>>) ->
    <<>>;
trim_right(BinString) ->
    case binary:last(BinString) of
        Blank when ?IS_BLANK(Blank) ->
            Size = size(BinString) - 1,
            <<Part:Size/binary, _/binary>> = BinString,
            trim_right(Part);
        _ ->
            BinString
    end.

-spec to_lower(BinString1) -> BinString2 when
        BinString1 :: binary_string(),
        BinString2 :: binary_string().
to_lower(BinString) ->
    << <<(maps:get(C, ?TO_LOWER, C))/utf8>> || <<C/utf8>> <= BinString>>.

-spec to_upper(BinString1) -> BinString2 when
        BinString1 :: binary_string(),
        BinString2 :: binary_string().
to_upper(BinString) ->
    << <<(maps:get(C, ?TO_UPPER, C))/utf8>> || <<C/utf8>> <= BinString>>.

%% Tests
-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").

split_test_() ->
[
    ?_assertEqual({<<"Before">>, <<"After">>},
        split(<<"Before After">>, <<" ">>))
].

split_global_test_() ->
[
    ?_assertEqual([<<"One">>,<<"two">>,<<"three">>],
        split_global(<<"One,two,three">>, <<",">>))
].

strip_test_() ->
[
    ?_assertEqual(<<"test  ">>, trim_left(<<"  test  ">>)),
    ?_assertEqual(<<"  test">>, trim_right(<<"  test  ">>)),
    ?_assertEqual(<<"test">>, trim(<<"  test  ">>))
].

to_lower_test_() ->
[
    ?_assertEqual(<<"  test  ">>, to_lower(<<"  TEST  ">>))
].

to_upper_test_() ->
[
    ?_assertEqual(<<"  TEST  ">>, to_upper(<<"  test  ">>))
].

-endif.

