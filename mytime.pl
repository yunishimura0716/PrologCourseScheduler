:- module(mytime, [filter_sections_by_time/5, overlaps_section/4, parse_time_string/2]).
:- format('time.pl is loaded~n').

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

% Parse time string into minutes past midnight
parse_time_string(TimeString, TimeInMinutes) :-
    % format(user_error, "parse time string is called, ~w~n", [TimeString]),
    split_string(TimeString, ":", "", [HourString, MinuteString]),
    number_string(Hour, HourString),
    number_string(Minute, MinuteString),
    TimeInMinutes is Hour * 60 + Minute.

% Check if a section overlaps with a time slot
overlaps_section(Day, StartInMinutes, EndInMinutes, section(_,_,_,_,_,_,_,_,_, days(DayList), time(StartHour, StartMinute), time(EndHour, EndMinute), _)) :-
    % format(user_error, "overlaps section is called: ~w~n", [DayList]),
    member(Day, DayList),

    SectionStartInMinutes is StartHour * 60 + StartMinute,
    SectionEndInMinutes is EndHour * 60 + EndMinute,

    % format(user_error, "Request Timeslots: ~w, ~w~n", [StartInMinutes, EndInMinutes]),
    % format(user_error, "Section Timeslots: ~w, ~w~n", [SectionStartInMinutes, SectionEndInMinutes]),
    ((SectionStartInMinutes >= StartInMinutes, SectionStartInMinutes < EndInMinutes);
      (SectionEndInMinutes > StartInMinutes, SectionEndInMinutes =< EndInMinutes)).

% Filter sections that do not overlap with the specified time slots
filter_sections_by_time(Sections, [], [], [], Sections).
filter_sections_by_time(Sections, [Day|DayRest], [Start|StartRest], [End|EndRest], FilteredSections) :-
  format(user_error, "filter sections by time: ~w, ~w~n", [Start, End]),
  parse_time_string(Start, ParsedStart),
  parse_time_string(End, ParsedEnd),

  exclude(overlaps_section(Day, ParsedStart, ParsedEnd), Sections, RestSections),
  filter_sections_by_time(RestSections, DayRest, StartRest, EndRest, FilteredSections).
