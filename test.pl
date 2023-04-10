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
:- use_module(mytime).
:- use_module(schedule).
:- use_module(main).
:- use_module(samplefacts).

% test for mytime.pl
:- parse_time_string("12:00", 720).
:- parse_time_string("09:10", 550).

:- overlaps_section(mon, 550, 720, section(_,_,_,_,_,_,_,_,_, days([mon, wed, fri]), time(10, 30), time(12, 0), _)).
:- overlaps_section(mon, 700, 800, section(_,_,_,_,_,_,_,_,_, days([mon, wed, fri]), time(10, 30), time(12, 0), _)).

:- filter_sections_by_time(
  [
    section(_,_,_,_,_,_,_,_,_, days([mon, wed, fri]), time(10, 30), time(12, 0), _),
    section(_,_,_,_,_,_,_,_,_, days([mon, wed, fri]), time(15, 0), time(16, 0), _),
    section(_,_,_,_,_,_,_,_,_, days([tue, thu]), time(10, 30), time(12, 0), _)
  ],
  [mon], ["09:10"], ["12:00"],
  [
    section(_,_,_,_,_,_,_,_,_, days([mon, wed, fri]), time(15, 0), time(16, 0), _),
    section(_,_,_,_,_,_,_,_,_, days([tue, thu]), time(10, 30), time(12, 0), _)
  ]
).

% test for schedule.pl
no_overlapping_sections([
  section(_,_,_,_,_,_,_,_,_, days([mon, wed, fri]), time(15, 0), time(16, 0), _),
  section(_,_,_,_,_,_,_,_,_, days([tue, thu]), time(15, 0), time(16, 0), _),
  section(_,_,_,_,_,_,_,_,_, days([tue, thu]), time(10, 0), time(12, 0), _)
]).

% test for main.pl
:- section_group(
  6,
  [
    section(3,cpsc,100,111,_,_,_,_,_, days([mon, wed, fri]), time(15, 0), time(16, 0), _),
    section(3,cpsc,110,111,_,_,_,_,_, days([tue, thu]), time(15, 0), time(16, 0), _),
    section(3,cpsc,121,111,_,_,_,_,_, days([mon, wed, fri]), time(12, 0), time(13, 0), _)
  ],
  [],
  [
    [
      section(3,cpsc,100,111_,_,_,_,_,_, days([mon, wed, fri]), time(15, 0), time(16, 0), _),
      section(3,cpsc,110,111_,_,_,_,_,_, days([tue, thu]), time(15, 0), time(16, 0), _)
    ],
    [
      section(3,cpsc,110,111_,_,_,_,_,_, days([tue, thu]), time(15, 0), time(16, 0), _),
      section(3,cpsc,121,111_,_,_,_,_,_, days([mon, wed, fri]), time(12, 0), time(13, 0), _)
    ],
    [
      section(3,cpsc,100,111_,_,_,_,_,_, days([mon, wed, fri]), time(15, 0), time(16, 0), _),
      section(3,cpsc,121,111_,_,_,_,_,_, days([mon, wed, fri]), time(12, 0), time(13, 0), _)
    ]
  ]
).
