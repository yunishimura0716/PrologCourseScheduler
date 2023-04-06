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
:- use_module(library(lists)).
:- use_module(samplefacts).

% facts files
:- consult('samplefacts.pl').

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

% Convert a section/11 fact to a JSON object
section_to_json(section(_, Course, Section, _, _, _, _, _, _, _, _, _, _), Json) :-
  Json = json{course:Course, section:Section}.
group_to_sections(Combination, CombinationJson) :-
  maplist(section_to_json, Combination, CombinationJson).

number_to_json(number, json) :- json = json{course: cpsc, number: number}.

in_section(Credit, Course, Number, Year, Semester, IsInPerson) :-
  section(Credit, Course, Number,_,_,lecture, Year, Semester,_,_,_,_, IsInPerson).

string_atom(String,Atom) :-
  atom_string(Atom,String).

is_string_list([]).
is_string_list([X|R]) :-
  string(X),
  is_string_list(R).

% Define the request handler
search_handler(Request) :-
  http_read_json_dict(Request, DictIn, [as(atom)]),
  % http_read_json_dict(Request, DictIn, []),

  format(user_error, "Request: ~w~n", [DictIn]),

  % extract courses
  get_dict(courses, DictIn, CoursesString), 
  is_string_list(CoursesString),
  % convert the string to atom for courses
  maplist(string_atom, CoursesString, Courses),
  % extract semester
  get_dict(semester, DictIn, SemesterString),
  atom_number(SemesterString, Semester),
  % extract is in person
  get_dict(in_person, DictIn, IsInPersonString),
  string_atom(IsInPersonString, IsInPerson),
  % get total credits
  get_dict(credits, DictIn, TotalCreditsString),
  atom_number(TotalCreditsString, TotalCredits),

  format(user_error, "extracted ~w,~w,~w,~w~n", [Courses, Semester, IsInPerson, TotalCredits]),

  % Process the course(s) to get the matching section(s)
  % findall(Section, (member(Course, Courses), in_section(Credit, Course, Number, Year, Semester, IsInPerson), Section = section(Credit, Course, Number,_,_,lecture, Year,_,_,_,_,_,_)), Sections),
  findall(section(Credit, Course, Number, _, _, lecture, Year, Semester, InPerson, Days, StartTime, EndTime, IsInPerson), (
    member(Course, Courses),
    in_section(Credit, Course, Number, Year, Semester, IsInPerson)
  ), Sections),
  % format(user_error, 'Sections: ~w~n', [Sections]),

  section_group(TotalCredits, Sections, SectionGroup),
  format(user_error, 'SectionGroup: ~w~n', [SectionGroup]),

  % Convert the matching section(s) to a JSON response
  maplist(group_to_sections, SectionGroup, JsonGroup),
  reply_json_dict(json{data:JsonGroup}).

  % Log the request and response
  % format(user_error, 'Response: ~w~n', [_{data: Sections}]).

% section_group(+TotalCredits, +Sections, -SectionGroup)
% SectionGroup is a list of lists of sections, where the total credits of each list of sections add up to TotalCredits
section_group(TotalCredits, Sections, SectionGroup) :-
    % Generate all possible combinations of sections whose total credits add up to TotalCredits
    (setof(Combination, get_combinations(TotalCredits, Sections, Combination), Combinations) ->
        % If get_combinations found some combinations, use them to build SectionGroup
        (
          % format(user_error, 'Combinations: ~w~n', [Combinations]),
          remove_duplicates(Combinations, UniqueCombinations),
          SectionGroup = UniqueCombinations
        );
        % Otherwise, return an empty list for SectionGroup
        SectionGroup = []
    ).

% get_combinations(+TotalCredits, +Sections, -Combination)
% Combination is a list of sections whose total credits add up to TotalCredits
get_combinations(TotalCredits, Sections, Combination) :-
    % Generate all possible combinations of sections
    combinations(Sections, Combination),
    % Calculate the total credits of the combination
    calculate_total_credits(Combination, Total),
    % Check if the total credits of the combination is equal to TotalCredits
    Total = TotalCredits, 
    % Check if any two sections in the combination have the same (dept, number) pair
    check_unique_combination(Combination),
     % Check if the combination is unique with respect to (dept, number)
    sort_sections(Combination, SortedCombination),
    \+ (member(Section, Combination), member(SortedSection, SortedCombination), Section \== SortedSection, same_dept_number(Section, SortedSection)).


% combinations(+List, -Combination)
% Combination is a list of elements of List
combinations([], []).
combinations([X|Xs], [X|Ys]) :-
    combinations(Xs, Ys).
combinations([_|Xs], Ys) :-
    combinations(Xs, Ys).

% calculate_total_credits(+Sections, -TotalCredits)
% TotalCredits is the sum of credits of all sections in Sections
calculate_total_credits([], 0).
calculate_total_credits([section(Credits, _, _, _, _, _, _, _, _, _, _, _, _)|Sections], TotalCredits) :-
    calculate_total_credits(Sections, RemainingCredits),
    TotalCredits is Credits + RemainingCredits.

% check_unique_combination(+Combination)
% Succeeds if all sections in the combination have a unique (dept, number) pair
check_unique_combination([]).
check_unique_combination([section(_, Dept, Number, _, _, _, _, _, _, _, _, _, _)|Sections]) :-
    % Check if the current section has a unique (dept, number) pair
    \+ member(section(_, Dept, Number, _, _, _, _, _, _, _, _, _, _), Sections),
    % Check if the remaining sections have unique (dept, number) pairs
    check_unique_combination(Sections),
    % If the previous goal succeeded, cut to prevent backtracking and return true
    !.
check_unique_combination(NotSections) :-
    % Handle the failure of check_unique_combination/1 when given a non-list input
    \+ is_list(NotSections),
    false.

% sort_sections(+Sections, -SortedSections)
% Sorts a list of sections by dept and number
sort_sections(Sections, SortedSections) :-
    maplist(sort_section, Sections, SortedSections).

% sort_section(+Section, -SortedSection)
% Sorts a section/12 term by dept, number, and section
sort_section(section(Credits, Dept, Number, _, _, _, _, _, _, _, _, _, _), section(Credits, SortedDept, SortedNumber, _, _, _, _, _, _, _, _, _, _)) :-
    sort([Dept, Number], [SortedDept, SortedNumber]).

% same_dept_number(+Section1, +Section2)
% True if Section1 and Section2 have the same (dept, number) pair
same_dept_number(section(_, Dept1, Number1, _, _, _, _, _, _, _, _, _, _), section(_, Dept2, Number2, _, _, _, _, _, _, _, _, _, _)) :-
    Dept1 == Dept2,
    Number1 == Number2.

same_combination([], []).
same_combination([], _) :- false.
same_combination(_, []) :- false.
same_combination([Section1|Rest1], [Section2|Rest2]) :-
    same_dept_number(Section1, Section2),
    same_combination(Rest1, Rest2).

% Remove duplicates from a list of combinations
remove_duplicates([], []).
remove_duplicates([Combination|Combinations], [Combination|UniqueCombinations]) :-
    % Exclude all combinations identical to the current combination
    exclude(same_combination(Combination), Combinations, RemainingCombinations),
    % Remove duplicates from the remaining combinations
    remove_duplicates(RemainingCombinations, UniqueCombinations).
remove_duplicates([_|Combinations], UniqueCombinations) :-
    % If the current combination is identical to a previous combination, skip it
    remove_duplicates(Combinations, UniqueCombinations).

% Start the server
server(Port) :-
    http_server(http_dispatch, [port(Port)]).

:- server(8000).
