:- module(main, [section_group/4]).

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
:- use_module(mytime).
:- use_module(schedule).
:- use_module(natl).

% facts files
:- consult('samplefacts.pl').

% Set the location of the HTML file
:- multifile http:location/3.
:- dynamic http:location/3.

http:location(html, '/templates', []).

% Define a route for serving the HTML file
:- http_handler(root(.), main_handler, []).
:- http_handler('/search', search_handler, [method(post)]).
:- http_handler('/natl', natl_get_handler, [method(get)]).
:- http_handler('/ask', natl_post_handler, [method(post)]).

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

natl_get_handler(Request) :-
    % Read the contents of the HTML file
    (   catch(read_file_to_string('templates/natl.html', Template, []), E, fail)
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

natl_post_handler(Request) :-
  % http_read_json_dict(Request, JSON), % http_read_json_dict(Request, DictIn, []),
  http_read_json_dict(Request, _{query:QueryString}),
  % atom_string(JSON.query, String),
  % format(user_error, "~n~w~n", H),
  % get_dict(query, DictIn, CoursesString), 
  split_string(QueryString, "\s", "\s", WordList),
  % write(WordList),
  ask(WordList, Ans),
  atom_string(Ans, AnsString),

  reply_json_dict(json{data:AnsString}).

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

atom_to_time_string(Hr, Mn, Time) :-
  atom_concat(Hr, ':', Result), atom_concat(Result, Mn, Time).
% Convert a section/11 fact to a JSON object
section_to_json(section(_, Course, Number, Section, _, _, _, _, _, days(DayList), time(StartHour, StartMinute), time(EndHour, EndMinute), _), Json) :-
  atom_to_time_string(StartHour, StartMinute, Start),
  atom_to_time_string(EndHour, EndMinute, End),
  Json = json{
    course:Course, 
    number: Number,
    section:Section,
    dayofweeks: DayList,
    start: Start,
    end: End
  }.
group_to_sections(Combination, CombinationJson) :-
  maplist(section_to_json, Combination, CombinationJson).

number_to_json(number, json) :- json = json{course: cpsc, number: number}.

string_atom(String,Atom) :-
  atom_string(Atom,String).

is_string_list([]).
is_string_list([X|R]) :-
  string(X),
  is_string_list(R).

specific_course_convert(Input, Output) :-
  get_dict(course, Input, CourseString),
  string_atom(CourseString, Course),
  get_dict(number, Input, NumberString),
  atom_number(NumberString, Number),
  Output = {
    course: Course,
    number: Number
  }.

filter_specific_courses(RequiredSections, {course: Course, number: Number}) :-
  member(section(_, Course, Number, _, _, _, _, _, _, _, _, _, _), RequiredSections).


% Define the request handler
search_handler(Request) :-
  http_read_json_dict(Request, DictIn, [as(atom)]),
  % http_read_json_dict(Request, DictIn, []),

  format(user_error, "~nRequest: ~w~n", [DictIn]),

  % extract courses
  get_dict(courses, DictIn, CoursesString), 
  maplist(string_atom, CoursesString, Courses),
  % extract years
  get_dict(years, DictIn, YearsString),
  maplist(atom_number, YearsString, Years),
  % extract semester
  get_dict(semester, DictIn, SemesterString),
  atom_number(SemesterString, Semester),
  % extract is in person
  get_dict(styles, DictIn, StylesString),
  maplist(string_atom, StylesString, Styles),
  % extract specific courses
  get_dict(specificCourses, DictIn, SpecificCoursesString),
  maplist(specific_course_convert, SpecificCoursesString, SpecificCourses),
  findall(section(Credit, Course, Number, Section, _, lecture, Year, Semester, Style, days(Days), StartTime, EndTime, _), (
    member({course: Course, number: Number}, SpecificCourses),
    member(Style, Styles),
    section(Credit, Course, Number, Section,_,lecture, Year, Semester, Style, days(Days), StartTime, EndTime, _)
  ), RequiredSections), 
  % format(user_error, 'RequiredSections: ~w~n', [RequiredSections]),
  include(filter_specific_courses(RequiredSections), SpecificCourses, RequiredCourses),
  % get total credits
  get_dict(credits, DictIn, TotalCreditsString),
  atom_number(TotalCreditsString, TotalCredits),

  format(user_error, "extracted ~w,~w,~w,~w,~w~n", [Courses, Years, Semester, Styles, TotalCredits]),
  format(user_error, "sp courses: ~w => required courses: ~w~n", [SpecificCourses, RequiredCourses]),

  % get day of weeks 
  get_dict(dayOfWeeks, DictIn, DayOfWeeksString),
  maplist(string_atom, DayOfWeeksString, DayOfWeeks),
  % get start times
  get_dict(startTimes, DictIn, StartTimes),
  % get end times
  get_dict(endTimes, DictIn, EndTimes),

  format(user_error, "extracted ~w,~w,~w~n", [DayOfWeeks, StartTimes, EndTimes]),

  % Process the course(s) to get the matching section(s)
  findall(section(Credit, Course, Number, Section, _, lecture, Year, Semester, Style, days(Days), StartTime, EndTime, _), (
    member(Course, Courses),
    member(Year, Years),
    member(Style, Styles),
    section(Credit, Course, Number, Section,_,lecture, Year, Semester, Style, days(Days), StartTime, EndTime, _)
  ), Sections), 
  % format(user_error, 'Sections: ~w~n', [Sections]),

  append(Sections, RequiredSections, AllSections),
  filter_sections_by_time(AllSections, DayOfWeeks, StartTimes, EndTimes, FilteredSections),
  % format(user_error, 'FilteredSections: ~w~n', [FilteredSections]),

  section_group(TotalCredits, FilteredSections, RequiredCourses, SectionGroup),
  length(SectionGroup, SectionGroupNum),
  format(user_error, 'SectionGroupNum: ~w~n', [SectionGroupNum]),

  % Convert the matching section(s) to a JSON response
  maplist(group_to_sections, SectionGroup, JsonGroup),
  reply_json_dict(json{data:JsonGroup}).

  % Log the request and response
  % format(user_error, 'Response: ~w~n', [_{data: Sections}]).

% section_group(+TotalCredits, +Sections, +RequiredCourses, -SectionGroup)
% SectionGroup is a list of lists of sections, where the total credits of each list of sections add up to TotalCredits
section_group(TotalCredits, Sections, RequiredCourses, SectionGroup) :-
    % Generate all possible combinations of sections whose total credits add up to TotalCredits
    (setof(Combination, get_combinations(TotalCredits, Sections, RequiredCourses, Combination), Combinations) ->
        % If get_combinations found some combinations, use them to build SectionGroup
        (
          % format(user_error, 'Combinations: ~w~n', [Combinations]),
          remove_duplicates(Combinations, UniqueCombinations),
          SectionGroup = UniqueCombinations
        );
        % Otherwise, return an empty list for SectionGroup
        SectionGroup = []
    ).

% get_combinations(+TotalCredits, +Sections, +RequiredCourses, -Combination)
% Combination is a list of sections whose total credits add up to TotalCredits
get_combinations(TotalCredits, Sections, RequiredCourses, Combination) :-
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
    \+ (member(Section, Combination), member(SortedSection, SortedCombination), Section \== SortedSection, same_dept_number(Section, SortedSection)),
    % Check if each section in the combination does not overlap with each other
    no_overlapping_sections(Combination),
    % Filter out combinations that do not include the required courses
    has_required_courses(RequiredCourses, Combination).


% combinations(+List, -Combination)
% Combination is a list of elements of List
combinations([], []).
combinations([X|Xs], [X|Ys]) :-
    combinations(Xs, Ys).
combinations([_|Xs], Ys) :-
    combinations(Xs, Ys).

% Check if a combination has all the required courses
has_required_courses([], _).
has_required_courses([{course: Course, number: Number}|Rest], Combination) :-
    member(section(_, Course, Number, _, _, _, _, _, _, _, _, _, _), Combination),
    has_required_courses(Rest, Combination).

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
same_dept_number(section(_, Dept1, Number1, Section1, _, _, _, _, _, _, _, _, _), section(_, Dept2, Number2, Seciton2, _, _, _, _, _, _, _, _, _)) :-
    Dept1 == Dept2,
    Number1 == Number2,
    Section1 == Section2.

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
