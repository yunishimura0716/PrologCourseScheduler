:- module(schedule, [no_overlapping_sections/1]).
:- format('schedule.pl is loaded~n').

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

% Check if each section in the list does not overlap with each other
no_overlapping_sections([]).
no_overlapping_sections([_]).
no_overlapping_sections([Section|Rest]) :-
    \+ overlaps_with_any(Section, Rest),
    no_overlapping_sections(Rest).

% Check if a section overlaps with any section in the list
overlaps_with_any(Section, [Other|_]) :-
    overlaps_section(Section, Other).
overlaps_with_any(Section, [_|Rest]) :-
    overlaps_with_any(Section, Rest).

overlaps_section(section(_, C1, N1, _, _, _, _, _, _, days(Days1), time(Start1Hour, Start1Minute), time(End1Hour, End1Minute), _),
                  section(_, C2, N2, _, _, _, _, _, _, days(Days2), time(Start2Hour, Start2Minute), time(End2Hour, End2Minute), _)) :-
    overlap_time(Days1, Start1Hour, Start1Minute, End1Hour, End1Minute, Days2, Start2Hour, Start2Minute, End2Hour, End2Minute).
    % format(user_error, "overlap_time_helper(~w~w) is called, ~w, ~w, ~w, ~w~n", [C1, N1, Start1Hour, Start1Minute, End1Hour, End1Minute]),
    % format(user_error, "overlap_time_helper(~w~w) is called, ~w, ~w, ~w, ~w~n", [C2, N2, Start2Hour, Start2Minute, End2Hour, End2Minute]).

% Check if two sections overlap in time
overlap_time(Days1, Start1Hour, Start1Minute, End1Hour, End1Minute, Days2, Start2Hour, Start2Minute, End2Hour, End2Minute) :-
    overlap_days(Days1, Days2),
    overlap_time_helper(Start1Hour, Start1Minute, End1Hour, End1Minute, Start2Hour, Start2Minute, End2Hour, End2Minute).

% Check if two sets of days overlap
overlap_days(Days1, Days2) :-
    member(Day, Days1),
    member(Day, Days2).

% Check if two times overlap
overlap_time_helper(Start1Hour, Start1Minute, End1Hour, End1Minute, Start2Hour, Start2Minute, End2Hour, End2Minute) :-
    time_to_minutes(Start1Hour, Start1Minute, Start1Minutes),
    time_to_minutes(End1Hour, End1Minute, End1Minutes),
    time_to_minutes(Start2Hour, Start2Minute, Start2Minutes),
    time_to_minutes(End2Hour, End2Minute, End2Minutes),
    overlap_intervals(Start1Minutes, End1Minutes, Start2Minutes, End2Minutes).

% Check if two time intervals overlap
overlap_intervals(Start1, End1, Start2, End2) :-
    ((Start1 >= Start2, Start1 < End2);
      (End1 > Start2, End1 =< End2)).

% Find the maximum of two numbers
max(A, B, A) :- A >= B.
max(A, B, B) :- A < B.

% Find the minimum of two numbers
min(A, B, A) :- A =< B.
min(A, B, B) :- A > B.

% Convert a time in hours and minutes to minutes
time_to_minutes(Hours, Minutes, TotalMinutes) :-
    TotalMinutes is Hours * 60 + Minutes.
