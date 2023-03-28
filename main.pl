:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).

% The predicate server(+Port) starts the server. It simply creates a
% number of Prolog threads and then returns to the toplevel, so you can
% (re-)load code, debug, etc.
server(Port) :-
        http_server(http_dispatch, [port(Port)]).

:- http_handler(/, http_reply_file('main.html', []), []).
