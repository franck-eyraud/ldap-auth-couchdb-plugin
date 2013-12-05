-module(ldap_auth).
-include_lib("couch/include/couch_db.hrl").
-include("include/eldap.hrl").

-export ([ldap_authentication_handler/1]).

basic_name_pw(Req) ->
    AuthorizationHeader = couch_httpd:header_value(Req, "Authorization"),
    case AuthorizationHeader of
    "Basic " ++ Base64Value ->
        case re:split(base64:decode(Base64Value), ":",
                      [{return, list}, {parts, 2}]) of
        ["_", "_"] ->
            % special name and pass to be logged out
            nil;
        [User, Pass] ->
            {User, Pass};
        _ ->
            nil 
        end;
    _ ->
        nil 
    end.

ldap_authentication_handler(Req) ->
    LDAPUrl = couch_config:get
        ("ldap_auth", "auth_ldap_url",
            "false"),
    case LDAPUrl of
    "false" ->
        throw({error, "No auth_ldap_url defined."});
    _ ->
        case basic_name_pw(Req) of
        {User, Pass} ->
            try eldap:parse_ldap_url(LDAPUrl) of
            {ok, LDAPServer, LDAPBindname, {attributes, [Attrdesc]}} ->
                {LDAPHost, LDAPPort} = LDAPServer,
                case length(LDAPBindname) of
                0->
                    throw({error, "LDAP URL is not correct."});
                _->
                    BaseDN = concat_bindname(LDAPBindname),
                    ?LOG_INFO("Host:~p, Port:~p ~n BaseDN: ~p ~n LDAPAttributes: ~p ~n", [LDAPHost, LDAPPort, BaseDN, Attrdesc]),
                    case eldap:open([LDAPHost], [{port, LDAPPort}]) of
                    {ok, LDAPHandler} ->
                        UserDNList = lists:append([Attrdesc ++ "=" ++ User], BaseDN),
                        UserDN = string_join(",", UserDNList),
                        ?LOG_INFO("UserDN : ~p ~n", [UserDN]),
                        case eldap:simple_bind(LDAPHandler, UserDN, Pass) of
                        ok ->
                            StrBaseDN = string_join(",", BaseDN),
                            ?LOG_INFO("Connected to LDAP Server with UserDN: ~p, Pass: ~p", [UserDN, Pass]),
                            {ok, {eldap_search_result, LDAPSearchResult, []}} = eldap:search(LDAPHandler,
                                [{base, StrBaseDN},
                                 {filter, eldap:equalityMatch("member", UserDN)},
                                 {attributes, [Attrdesc]}]),
                            ?LOG_INFO("LDAPSearchResult: ~p", [LDAPSearchResult]),
                            case length(LDAPSearchResult) of
                            0 ->
                                Req#httpd{user_ctx=#user_ctx{name=?l2b(User)}};
                            _ ->
                                Roles = ldap_groups(LDAPSearchResult, []),
                                ?LOG_INFO("User: ~p Roles:~p", [User, Roles]),
                                Req#httpd{user_ctx=#user_ctx{name=?l2b(User), roles=Roles}}
                            end;
                        {error,invalidCredentials} ->
                            Req; %throw({unauthorized, <<"Name or password is incorrect.">>});
                        _ ->
                            throw({error, "Unable to validate user on LDAP server."})
                        end;
                    _->
                        ?LOG_ERROR("Unable to connect to LDAP, Host: ~p Port: ~p", [LDAPHost, LDAPPort]),
                        throw({error, "Unable to bind to LDAP server."})
                    end
                end
            catch
                error: _ ->
                    throw({error, "LDAP URL parse error."})
            end;
        nil ->
            case couch_server:has_admins() of
            true ->
                ?LOG_INFO("has admins",[]),
                Req;
            false ->
                ?LOG_INFO("has no admin",[]),
                case couch_config:get("couch_httpd_auth", "require_valid_user", "false") of
                    "true" ->
                        ?LOG_INFO("require valid user",[]),
                        Req;
                    _ ->
                        ?LOG_INFO("don't require valid user",[]),
                        Req#httpd{user_ctx=#user_ctx{roles=[<<"_admin">>]}}
                end
            end
        end
    end.
ldap_groups([], Acc) ->
    [list_to_binary(R) || R<-Acc];
ldap_groups([C | Rest], Acc) ->
    {eldap_entry,LDAPRecord, [{_, [GroupAttr]}]} = C,
    ldap_groups(Rest, [GroupAttr | Acc]).

concat_bindname(Bindname) ->
    concat_bindname(Bindname, []).
concat_bindname([], Acc) -> lists:reverse(Acc);
    %[list_to_binary(R) || R<-lists:reverse(Acc)];
concat_bindname([C | Rest], Acc) ->
    [{attribute_type_and_value, Name, Value}] = C,
    concat_bindname(Rest, [Name ++ "=" ++ Value | Acc]).

string_join(Join, L) ->
    string_join(Join, L, fun(E) -> E end).

string_join(_Join, L=[], _Conv) ->
    L;
string_join(Join, [H|Q], Conv) ->
    lists:flatten(lists:concat(
        [Conv(H)|lists:map(fun(E) -> [Join, Conv(E)] end, Q)]
    )).


