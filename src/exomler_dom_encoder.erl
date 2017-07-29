-module(exomler_dom_encoder).

%% API
-export([encode_document/1]).
-export([encode/1]).

%% API
encode_document({xml, Version, Encoding, RootEntity}) when 
        is_atom(Version), is_atom(Encoding), is_tuple(RootEntity) ->
    Prolog = prolog(version(Version), encoding(Encoding)),
    Root = tag(RootEntity),
    <<Prolog/binary, Root/binary>>.

encode(Entity) when is_tuple(Entity)->
    tag(Entity).

%% internal
prolog(Version, Encoding) ->
    Attrs = [{<<"version">>, Version}, {<<"encoding">>, Encoding}],
    BinAttrs = tag_attrs(Attrs),
    <<"<?xml", BinAttrs/binary, " ?>\n">>.

version('1.0') -> <<"1.0">>;
version('1.1') -> <<"1.1">>.

encoding(latin1) -> <<"ISO-8859-1">>;
encoding(utf8) -> <<"UTF-8">>.

tag({Tag, Attrs, Content}) ->
    BinAttrs = tag_attrs(Attrs),
    BinContent = << <<(content(SubTag))/binary>> || SubTag <- Content>>,
    Tag1 = bstring:trim_left(Tag),
    <<"<", Tag1/binary, BinAttrs/binary, ">", BinContent/binary, 
        "</", Tag1/binary, ">">>.

tag_attrs(Attrs) ->
    tag_attrs(Attrs, <<>>).

tag_attrs([{Key, Value}|Tail], EncodedAttrs) ->
    EscapedValue = escape(Value),
    EncodedAttr = <<" ", Key/binary, "=\"", EscapedValue/binary, "\"">>, 
    tag_attrs(Tail, <<EncodedAttrs/binary, EncodedAttr/binary>>);
tag_attrs([], EncodedAttrs) ->
    EncodedAttrs.

content(Tuple) when is_tuple(Tuple) ->
    tag(Tuple);
content(Binary) when is_binary(Binary) ->
    escape(Binary).

escape(Bin) -> escape(Bin, <<>>).

escape(<<"\"", Rest/binary>>, Escaped) ->
    escape(Rest, <<Escaped/binary, "&quot;">>);
escape(<<"'", Rest/binary>>, Escaped) ->
    escape(Rest, <<Escaped/binary, "&apos;">>);
escape(<<"<", Rest/binary>>, Escaped) ->
    escape(Rest, <<Escaped/binary, "&lt;">>);
escape(<<">", Rest/binary>>, Escaped) ->
    escape(Rest, <<Escaped/binary, "&gt;">>);
escape(<<"&", Rest/binary>>, Escaped) ->
    escape(Rest, <<Escaped/binary, "&amp;">>);
escape(<<C:1/binary, Rest/binary>>, Escaped) ->
    escape(Rest, <<Escaped/binary, C/binary>>);
escape(<<>>, Escaped) ->
    Escaped.


%% Tests
-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").

encode_document_test_() ->
    [
    ?_assertEqual(<<"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n<html></html>">>, 
        encode_document({xml, '1.0', utf8, {<<"html">>, [], []}}))
    ].

encode_tag_test_() ->
    [
    ?_assertEqual(<<"<html></html>">>, 
        encode({<<"html">>, [], []}))
    ].

encode_content_test_() ->
    [
    ?_assertEqual(<<"<html>Body</html>">>, 
        encode({<<"html">>, [], [<<"Body">>]})),
    ?_assertEqual(<<"<html>TextBefore<head>Body</head>TextAfter</html>">>, 
        encode({<<"html">>, [], [<<"TextBefore">>, {<<"head">>, [], [<<"Body">>]}, <<"TextAfter">>]}))
    ].

encode_attributes_test_() -> 
    [
    ?_assertEqual(<<"<html xmlns=\"w3c\"></html>">>, 
        encode({<<"html">>, [{<<"xmlns">>,<<"w3c">>}], []})),
    ?_assertEqual(<<"<foo bar=\"&amp;&lt;&gt;\"></foo>">>, 
        encode({<<"foo">>, [{<<"bar">>,<<"&<>">>}], []}))
    ].

-endif.
