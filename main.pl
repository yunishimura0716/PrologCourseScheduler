:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/html_write)).
:- use_module(library(http/http_files)).
:- use_module(library(http/http_path)).
:- use_module(library(http/http_server_files)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_client)).
:- use_module(library(http/http_error)).
:- use_module(library(http/http_header)).
:- use_module(library(http/http_server)).
:- use_module(library(http/http_multipart_plugin)).

% Set the location of the HTML file
:- multifile http:location/3.
:- dynamic http:location/3.

http:location(html, '/templates', []).

% Define a route for serving the HTML file
:- http_handler(root(.), main_handler, []).
:- http_handler('/search', search_handler, [method(post)]).

% Define the request handler
main_handler(Request) :-
    % Read the contents of the HTML file
    (   catch(read_file_to_string('templates/main.html', Template, []), E, fail)
    ->  % Define variables to be substituted in the template
        Title = "UBC Course Scheduler",
        (   catch(read_file_to_string('templates/body.html', Body, []), E, fail)
        ->  % Replace variables in the template with their values
            substitute(Template, [
                var(title, Title),
                var(body, Body)
            ], HTML),
            % Send the HTML response
            format('Content-type: text/html~n~n'),
            format('~w', [HTML])
        ;   % Handle error when body file cannot be read
            format('Content-type: text/plain~n~n'),
            format('Error reading body file: ~w', [E])
        )
    ;   % Handle error when main file cannot be read
        format('Content-type: text/plain~n~n'),
        format('Error reading main file: ~w', [E])
    ).

% Define a helper predicate to substitute variables in the template
substitute(Template, [], Template).
substitute(Template, [var(Name, Value)|Vars], Result) :-
    (   nonvar(Template),
        nonvar(Name),
        nonvar(Value)
    ->  % Concatenate the variable name and placeholder delimiters
        atomic_list_concat(['{{', Name, '}}'], Placeholder),

        % Concatenate the variable value as a string
        atom_string(ValueAtom, Value),

        % Replace the placeholder with the variable value in the template
        atomic_list_concat(Split, Placeholder, Template),
        atomic_list_concat(Split, ValueAtom, NewTemplate),

        % Recursively substitute the remaining variables in the template
        substitute(NewTemplate, Vars, Result)
    ;   % Handle errors
        format('Content-type: text/plain~n~n'),
        format('An error occurred while processing the request.~n')
    ).

% Define the request handler
search_handler(Request) :-
  http_read_json(Request, Data),
  % process JSONIn
  % ...
  % return response

  % Return the same data back as a response
  reply_json(Data).

% Start the server
server(Port) :-
    http_server(http_dispatch, [port(Port)]).

:- server(8000).
