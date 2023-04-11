:- module(natl, [ask/2]).
:- format('natl.pl is loaded~n').
:- discontiguous natl:named/2, natl:course/1, natl:credits/2, natl:in_dept/2, natl:prereqs/2.
/*

"What sections of CPSC 110 start before 10 AM?"
"Which sections of CPSC 110 start before 10 AM?"

"which cpsc312 section starts before two on MWF?"
"what cpsc312 section starts before two on MWF?"

"what courses require cpsc221?"                   
"what are the prereqs for cpsc312?"                
"what are the prereqs of the prereqs of cpsc312?"
"what courses require the prereqs of cpsc312?"

TODO: finish this
"what is a 3-credit cpsc course?"        
"what is a 3-credit 4th-year cpsc course?"

*/
 
/*
  parts of the natural language grammar below are from: 
  Poole and Mackworth, Artificial Intelligence: foundations of computational agents, Cambridge, 2017
*/

noun_phrase(L0,L4,Ind,C0,C4) :-
    det(L0,L1,Ind,C3,C4),
    adjectives(L1,L2,Ind,C2,C3),
    noun(L2,L3,Ind,C1,C2),
    omp(L3,L4,Ind,C0,C1).

det(["the" | L],L,_,C,C).
det(["a" | L],L,_,C,C).
det(L,L,_,C,C).

adjectives(L0,L2,Ind,C0,C2) :-
    adj(L0,L1,Ind,C0,C1),
    adjectives(L1,L2,Ind,C1,C2).
adjectives(L,L,_,C,C).

mp(L0,L2,Subject,C0,C2) :-
    reln(L0,L1,Subject,Object,C0,C1),
    aphrase(L1,L2,Object,C1,C2).
mp(["that"|L0],L2,Subject,C0,C2) :-
    reln(L0,L1,Subject,Object,C0,C1),
    aphrase(L1,L2,Object,C1,C2).

omp(L0,L1,E,C0,C1) :-
    mp(L0,L1,E,C0,C1).
omp(L,L,_,C,C).

aphrase(L0, L1, E, C0,C1) :- noun_phrase(L0, L1, E,C0,C1).
aphrase(L0, L1, E,C0,C1) :- mp(L0, L1, E,C0,C1).

% DICTIONARY
% DeptName either describes Course or Section
adj([CourseName| L],L,Ind,[named(Course,CourseName), course(Course), of(Ind, Course)|C],C).
adj([DeptName | L],L,Ind, [named(Dept, DeptName), dept(Dept), in_dept(Ind, Dept)|C],C).
adj([DeptName | L],L,Ind, [named(Dept, DeptName), dept(Dept), in_dept(Course, Dept), of(Ind, Course)|C],C).
adj([Credits, "credit" | L],L,Ind, [number_codes(NCredits, Credits), credits(Ind, NCredits)|C],C).

noun(["course", "sections" | L], L,Ind,[section(Ind)|C],C).
noun(["prereqs"|L],["prereqs"|L],Ind,[course(Ind)|C],C).
noun(["sections" | L], ["sections" | L],Ind,[section(Ind)|C],C).
noun(["section" | L], L,Ind,[section(Ind)|C],C).
noun(["course" | L],L,Ind, [course(Ind)|C],C).
noun(["courses" | L],L,Ind, [course(Ind)|C],C).
noun([N | L],L,Ind, C,C) :- named(Ind, N). % Parse fails if there is no entity for name

% reln(L0,L1,Sub,Obj,C0,C1) is true if L0-L1 is a relation on individuals Sub and Obj
reln(["on"|L],L,Sub,Obj,[on(Sub,Obj)|C],C).
reln(["is","on"| L],L,Sub,Obj,[on(Sub,Obj)|C],C).
reln(["are","on"| L],L,Sub,Obj,[on(Sub,Obj)|C],C).
reln(["starts","before"|L],L,Sub,Obj,[starts_before(Sub,Obj)|C],C).
reln(["start","before"|L],L,Sub,Obj,[starts_before(Sub,Obj)|C],C).
reln(["start","before"|L],L,Sub,Obj,[starts_before(Obj,Sub)|C],C).
reln(["starts","after"|L],L,Sub,Obj,[starts_after(Sub,Obj)|C],C).
reln(["start","after"|L],L,Sub,Obj,[starts_after(Sub,Obj)|C],C).
% relates sections of a course to the course
reln(["sections", "of"|L],L,Sub,Obj,[of(Sub,Obj)|C],C).

% relates prerequisites
reln(["prereqs", "of"|L],L,Sub,Obj, [prereq(Obj,Sub)|C],C).
reln(["require"|L],L,Sub,Obj,[prereq(Sub,Obj)|C],C).

% question(Question,QR,Ind) is true if Query provides an answer about Ind to Question
question(["is" | L0],L2,Ind,C0,C2) :-
  noun_phrase(L0,L1,Ind,C0,C1),
  mp(L1,L2,Ind,C1,C2).
question(["what","is" | L0], L1, Ind,C0,C1) :-
  aphrase(L0,L1,Ind,C0,C1).
question(["what","are" | L0], L1, Ind,C0,C1) :-
  aphrase(L0,L1,Ind,C0,C1).  
question(["what" | L0],L2,Ind,C0,C2) :-
  noun_phrase(L0,L1,Ind,C0,C1),
  mp(L1,L2,Ind,C1,C2).
question(["what" | L0],L1,Ind,C0,C1) :-
  mp(L0,L1,Ind,C0,C1).
question(["which" | L0],L2,Ind,C0,C2) :-
  noun_phrase(L0,L1,Ind,C0,C1),
  mp(L1,L2,Ind,C1,C2).
question(["which" | L0],L1,Ind,C0,C1) :-
  mp(L0,L1,Ind,C0,C1).
question(["test"|[]],X,Ind,[dept(Ind)|C1],C1).

%named
course(cpsc121). course(cpsc221).

course(cpsc312).
credits(cpsc312,3).
in_dept(cpsc312,cpsc).
% coreq(cpsc312).
section(cpsc312_201). 
lecture(cpsc312_201).
of(cpsc312_201, cpsc312).
starts_at(cpsc312_201, time(12,0)). 
on(cpsc312_201, [mon, wed, fri]).

% true if courseB is prereq in CourseA prereq list
prereq(CourseA,CourseB) :-
  prereqs(CourseA, Reqs), in(CourseB, Reqs).
  
in(H, [H | T]).
in(A, [H | T]) :- in(A, T).

starts_after(Section, StartTime) :-
  starts_at(Section,Time),
  \+ before(Time, StartTime).
starts_before(Section, StartTime) :-
  starts_at(Section, Time),
  before(Time, StartTime).

before(time(H1,_),time(H2,_)) :- H1 < H2.
before(time(H,M1),time(H,M2)) :- M1 < M2.

credits(math221, 3).

ask(Q,A) :-
    get_constraints_from_question(Q,A,C),
    prove_all(C).

get_constraints_from_question(Q,A,C) :-
    question(Q,End,A,C,[]),
    member(End,[[],["?"],["."]]).

prove_all([]).
prove_all([H|T]) :-
    call(H),      % built-in Prolog predicate calls an atom
    prove_all(T).

% useful for testing
q(Ans) :-
    write("Ask me: "), flush_output(current_output), 
    read_line_to_string(user_input, St), 
    split_string(St, " -", " ,?.!-", Ln), % ignore punctuation
    ask(Ln, Ans).
q(Ans) :-
    write("No more answers\n"),
    q(Ans).


% FACTS
% utility string maps
named([mon, wed, fri], "MWF").
named([mon, wed, fri], "Monday, Wednesday, Friday").
named([mon, wed], "MW").
named([tue, thu], "TT").
named([tue, thu], "Tuesday, Thursday").
named(time(8,00),"8:00").
named(time(8,30),"8:30").
named(time(9,0),"9:00").
named(time(9,0),"9").
named(time(9,0),"nine").
named(time(9,30),"9:30").
named(time(10,0),"10:00").
named(time(10,30),"10:30").
named(time(11,0),"11:00").
named(time(11,30),"11:30").
named(time(12,30),"12:00").
named(time(12,30),"12:30").
named(time(13,0),"13:00").
named(time(13,30),"13:30").
named(time(14,0),"14:00").
named(time(14,0),"2").
named(time(14,0),"2 PM").
named(time(14,0),"two").
named(time(14,30),"14:30").
named(time(15,0),"15:00").
named(time(15,30),"15:30").
named(time(16,0),"16:00").
named(time(16,30),"16:30").
named(time(17,0),"17:00").
named(time(17,30),"17:30").
named(time(18,0),"18:00").
named(time(18,30),"18:30").
named(time(19,0),"19:00").
named(time(19,30),"19:30").
named(time(20,0),"20:00").
named(time(20,30),"20:30").
named(time(21,0),"21:00").
named(time(21,30),"21:30").
named(cpsc312, "cpsc312"). 
named(cpsc221, "cpsc221"). 
named(cpsc221, "cpsc110").
named(cpsc, "cpsc").
named(cpsc, "CPSC").
dept(cpsc).
dept(math).
dept(econ).
dept(biol).
dept(phys).


named(biol111,"biol111"). course(biol111). credits(biol111,3). in_dept(biol111,biol).
named(biol112,"biol112"). course(biol112). credits(biol112,3). in_dept(biol112,biol). prereqs(biol112,[chem100,chem110,chem111,biol111]).
named(biol121,"biol121"). course(biol121). credits(biol121,3). in_dept(biol121,biol). prereqs(biol121,[biol111]).
named(biol155,"biol155"). course(biol155). credits(biol155,6). in_dept(biol155,biol). prereqs(biol155,[chem100,chem110,chem111,biol111]).
named(biol180,"biol180"). course(biol180). credits(biol180,2). in_dept(biol180,biol). prereqs(biol180,[biol111]).
named(biol200,"biol200"). course(biol200). credits(biol200,3). in_dept(biol200,biol).
named(biol201,"biol201"). course(biol201). credits(biol201,3). in_dept(biol201,biol).
named(biol203,"biol203"). course(biol203). credits(biol203,4). in_dept(biol203,biol).
named(biol204,"biol204"). course(biol204). credits(biol204,4). in_dept(biol204,biol).
named(biol205,"biol205"). course(biol205). credits(biol205,4). in_dept(biol205,biol).
named(biol209,"biol209"). course(biol209). credits(biol209,4). in_dept(biol209,biol).
named(biol210,"biol210"). course(biol210). credits(biol210,4). in_dept(biol210,biol).
named(biol230,"biol230"). course(biol230). credits(biol230,3). in_dept(biol230,biol). prereqs(biol230,[biol121,scie001]).
named(biol234,"biol234"). course(biol234). credits(biol234,3). in_dept(biol234,biol).
named(biol260,"biol260"). course(biol260). credits(biol260,3). in_dept(biol260,biol).
named(biol300,"biol300"). course(biol300). credits(biol300,3). in_dept(biol300,biol).
named(biol301,"biol301"). course(biol301). credits(biol301,3). in_dept(biol301,biol).
named(biol306,"biol306"). course(biol306). credits(biol306,3). in_dept(biol306,biol).
named(biol310,"biol310"). course(biol310). credits(biol310,3). in_dept(biol310,biol).
named(biol320,"biol320"). course(biol320). credits(biol320,4). in_dept(biol320,biol).
named(biol321,"biol321"). course(biol321). credits(biol321,3). in_dept(biol321,biol).
named(biol323,"biol323"). course(biol323). credits(biol323,3). in_dept(biol323,biol).
named(biol324,"biol324"). course(biol324). credits(biol324,3). in_dept(biol324,biol).
named(biol325,"biol325"). course(biol325). credits(biol325,3). in_dept(biol325,biol).
named(biol326,"biol326"). course(biol326). credits(biol326,3). in_dept(biol326,biol).
named(biol327,"biol327"). course(biol327). credits(biol327,3). in_dept(biol327,biol). prereqs(biol327,[biol121,scie001]).
named(biol331,"biol331"). course(biol331). credits(biol331,4). in_dept(biol331,biol).
named(biol332,"biol332"). course(biol332). credits(biol332,4). in_dept(biol332,biol).
named(biol335,"biol335"). course(biol335). credits(biol335,3). in_dept(biol335,biol). prereqs(biol335,[biol233,biol234,micb322,frst302]).
named(biol336,"biol336"). course(biol336). credits(biol336,3). in_dept(biol336,biol). prereqs(biol336,[biol233,biol234]).
named(biol337,"biol337"). course(biol337). credits(biol337,3). in_dept(biol337,biol).
named(biol338,"biol338"). course(biol338). credits(biol338,4). in_dept(biol338,biol). prereqs(biol338,[biol234,biol233,frst302]).
named(biol340,"biol340"). course(biol340). credits(biol340,2). in_dept(biol340,biol).
named(biol341,"biol341"). course(biol341). credits(biol341,2). in_dept(biol341,biol).
named(biol342,"biol342"). course(biol342). credits(biol342,2). in_dept(biol342,biol).
named(biol343,"biol343"). course(biol343). credits(biol343,3). in_dept(biol343,biol).
named(biol344,"biol344"). course(biol344). credits(biol344,3). in_dept(biol344,biol).
named(biol346,"biol346"). course(biol346). credits(biol346,3). in_dept(biol346,biol).
named(biol347,"biol347"). course(biol347). credits(biol347,3). in_dept(biol347,biol).
named(biol351,"biol351"). course(biol351). credits(biol351,4). in_dept(biol351,biol).
named(biol352,"biol352"). course(biol352). credits(biol352,3). in_dept(biol352,biol).
named(biol362,"biol362"). course(biol362). credits(biol362,3). in_dept(biol362,biol).
named(biol363,"biol363"). course(biol363). credits(biol363,2). in_dept(biol363,biol).
named(biol364,"biol364"). course(biol364). credits(biol364,3). in_dept(biol364,biol).
named(biol370,"biol370"). course(biol370). credits(biol370,3). in_dept(biol370,biol).
named(biol371,"biol371"). course(biol371). credits(biol371,3). in_dept(biol371,biol).
named(biol372,"biol372"). course(biol372). credits(biol372,3). in_dept(biol372,biol).
named(biol398,"biol398"). course(biol398). credits(biol398,3). in_dept(biol398,biol).
named(biol399,"biol399"). course(biol399). credits(biol399,3). in_dept(biol399,biol).
named(biol402,"biol402"). course(biol402). credits(biol402,3). in_dept(biol402,biol).
named(biol403,"biol403"). course(biol403). credits(biol403,3). in_dept(biol403,biol).
named(biol404,"biol404"). course(biol404). credits(biol404,3). in_dept(biol404,biol).
named(biol406,"biol406"). course(biol406). credits(biol406,4). in_dept(biol406,biol).
named(biol411,"biol411"). course(biol411). credits(biol411,3). in_dept(biol411,biol). prereqs(biol411,[biol205,biol327,apbi327]).
named(biol415,"biol415"). course(biol415). credits(biol415,3). in_dept(biol415,biol).
named(biol416,"biol416"). course(biol416). credits(biol416,3). in_dept(biol416,biol). prereqs(biol416,[biol230,frst201]).
named(biol418,"biol418"). course(biol418). credits(biol418,3). in_dept(biol418,biol).
named(biol420,"biol420"). course(biol420). credits(biol420,3). in_dept(biol420,biol).
named(biol421,"biol421"). course(biol421). credits(biol421,3). in_dept(biol421,biol).
named(biol424,"biol424"). course(biol424). credits(biol424,3). in_dept(biol424,biol).
named(biol427,"biol427"). course(biol427). credits(biol427,3). in_dept(biol427,biol).
named(biol428,"biol428"). course(biol428). credits(biol428,3). in_dept(biol428,biol).
named(biol430,"biol430"). course(biol430). credits(biol430,3). in_dept(biol430,biol). prereqs(biol430,[biol335,biol336,biol338]).
named(biol431,"biol431"). course(biol431). credits(biol431,3). in_dept(biol431,biol).
named(biol432,"biol432"). course(biol432). credits(biol432,3). in_dept(biol432,biol).
named(biol433,"biol433"). course(biol433). credits(biol433,3). in_dept(biol433,biol).
named(biol434,"biol434"). course(biol434). credits(biol434,3). in_dept(biol434,biol).
named(biol437,"biol437"). course(biol437). credits(biol437,3). in_dept(biol437,biol). prereqs(biol437,[biol331,biol335,biol201,bioc202,bioc203]).
named(biol438,"biol438"). course(biol438). credits(biol438,3). in_dept(biol438,biol). prereqs(biol438,[phys101,phys106,phys107,phys117,phys131,phys157,scie001,biol325]).
named(biol440,"biol440"). course(biol440). credits(biol440,3). in_dept(biol440,biol). prereqs(biol440,[biol335,biol338]).
named(biol441,"biol441"). course(biol441). credits(biol441,3). in_dept(biol441,biol). prereqs(biol441,[biol340,biol341,biol361,biol362]).
named(biol445,"biol445"). course(biol445). credits(biol445,3). in_dept(biol445,biol).
named(biol447,"biol447"). course(biol447). credits(biol447,3). in_dept(biol447,biol).
named(biol448a,"biol448a"). course(biol448a). credits(biol448a,3). in_dept(biol448a,biol).
named(biol448b,"biol448b"). course(biol448b). credits(biol448b,3). in_dept(biol448b,biol).
named(biol448d,"biol448d"). course(biol448d). credits(biol448d,6). in_dept(biol448d,biol).
named(biol448g,"biol448g"). course(biol448g). credits(biol448g,3). in_dept(biol448g,biol).
named(biol449,"biol449"). course(biol449). credits(biol449,6). in_dept(biol449,biol).
named(biol450,"biol450"). course(biol450). credits(biol450,3). in_dept(biol450,biol). prereqs(biol450,[biol361,biol362,biol364,biol370,biol371,biol201,bioc202,bioc203,biol457]).
named(biol451,"biol451"). course(biol451). credits(biol451,3). in_dept(biol451,biol). prereqs(biol451,[biol371,biol372,caps301,psyc304,psyc367,psyc370]).
named(biol453,"biol453"). course(biol453). credits(biol453,4). in_dept(biol453,biol). prereqs(biol453,[biol204,biol205,biol327,apbi327,biol361,biol364,biol370,biol371,apbi311]).
named(biol454,"biol454"). course(biol454). credits(biol454,3). in_dept(biol454,biol). prereqs(biol454,[biol362,biol364]).
named(biol457,"biol457"). course(biol457). credits(biol457,3). in_dept(biol457,biol).
named(biol458,"biol458"). course(biol458). credits(biol458,3). in_dept(biol458,biol).
named(biol460,"biol460"). course(biol460). credits(biol460,3). in_dept(biol460,biol). prereqs(biol460,[biol372,caps301,psyc304,psyc367,psyc370]).
named(biol462,"biol462"). course(biol462). credits(biol462,3). in_dept(biol462,biol).
named(biol463,"biol463"). course(biol463). credits(biol463,3). in_dept(biol463,biol).
named(biol464,"biol464"). course(biol464). credits(biol464,3). in_dept(biol464,biol).
named(biol498,"biol498"). course(biol498). credits(biol498,3). in_dept(biol498,biol).
named(biol499,"biol499"). course(biol499). credits(biol499,3). in_dept(biol499,biol). prereqs(biol499,[biol399,biol498]).
named(cpsc100,"cpsc100"). course(cpsc100). credits(cpsc100,3). in_dept(cpsc100,cpsc).
named(cpsc103,"cpsc103"). course(cpsc103). credits(cpsc103,3). in_dept(cpsc103,cpsc).
named(cpsc107,"cpsc107"). course(cpsc107). credits(cpsc107,3). in_dept(cpsc107,cpsc).
named(cpsc110,"cpsc110"). course(cpsc110). credits(cpsc110,4). in_dept(cpsc110,cpsc).
named(cpsc121,"cpsc121"). course(cpsc121). credits(cpsc121,4). in_dept(cpsc121,cpsc).
named(cpsc203,"cpsc203"). course(cpsc203). credits(cpsc203,3). in_dept(cpsc203,cpsc). prereqs(cpsc203,[cpsc103,cpsc110,eosc211,math210,phys210,comm337]).
named(cpsc210,"cpsc210"). course(cpsc210). credits(cpsc210,4). in_dept(cpsc210,cpsc). prereqs(cpsc210,[cpsc107,cpsc110]).
named(cpsc213,"cpsc213"). course(cpsc213). credits(cpsc213,4). in_dept(cpsc213,cpsc). prereqs(cpsc213,[cpsc121,cpsc210]).
named(cpsc221,"cpsc221"). course(cpsc221). credits(cpsc221,4). in_dept(cpsc221,cpsc). prereqs(cpsc221,[cpsc210,cpen221,cpsc121,math220]).
named(cpsc259,"cpsc259"). course(cpsc259). credits(cpsc259,4). in_dept(cpsc259,cpsc).
named(cpsc298,"cpsc298"). course(cpsc298). credits(cpsc298,3). in_dept(cpsc298,cpsc).
named(cpsc302,"cpsc302"). course(cpsc302). credits(cpsc302,3). in_dept(cpsc302,cpsc). prereqs(cpsc302,[cpsc103,cpsc110,cpen221,eosc211,phys210,math101,math103,math105,math121,scie001,math152,math221,math223]).
named(cpsc303,"cpsc303"). course(cpsc303). credits(cpsc303,3). in_dept(cpsc303,cpsc). prereqs(cpsc303,[cpsc103,cpsc110,cpen221,eosc211,phys210,math101,math103,math105,math121,scie001,math152,math221,math223]).
named(cpsc304,"cpsc304"). course(cpsc304). credits(cpsc304,3). in_dept(cpsc304,cpsc).
named(cpsc310,"cpsc310"). course(cpsc310). credits(cpsc310,4). in_dept(cpsc310,cpsc). prereqs(cpsc310,[cpsc213,cpsc221]).
named(cpsc312,"cpsc312"). course(cpsc312). credits(cpsc312,3). in_dept(cpsc312,cpsc). prereqs(cpsc312,[cpsc210,cpen221]).
named(cpsc313,"cpsc313"). course(cpsc313). credits(cpsc313,3). in_dept(cpsc313,cpsc). prereqs(cpsc313,[cpsc213,cpsc221]).
named(cpsc314,"cpsc314"). course(cpsc314). credits(cpsc314,3). in_dept(cpsc314,cpsc).
named(cpsc317,"cpsc317"). course(cpsc317). credits(cpsc317,3). in_dept(cpsc317,cpsc). prereqs(cpsc317,[cpsc213,cpsc221]).
named(cpsc319,"cpsc319"). course(cpsc319). credits(cpsc319,4). in_dept(cpsc319,cpsc).
named(cpsc320,"cpsc320"). course(cpsc320). credits(cpsc320,3). in_dept(cpsc320,cpsc).
named(cpsc322,"cpsc322"). course(cpsc322). credits(cpsc322,3). in_dept(cpsc322,cpsc).
named(cpsc330,"cpsc330"). course(cpsc330). credits(cpsc330,3). in_dept(cpsc330,cpsc).
named(cpsc340,"cpsc340"). course(cpsc340). credits(cpsc340,3). in_dept(cpsc340,cpsc).
named(cpsc344,"cpsc344"). course(cpsc344). credits(cpsc344,3). in_dept(cpsc344,cpsc). prereqs(cpsc344,[cpsc210,cpen221]).
named(cpsc349,"cpsc349"). course(cpsc349). credits(cpsc349,0). in_dept(cpsc349,cpsc).
named(cpsc368,"cpsc368"). course(cpsc368). credits(cpsc368,3). in_dept(cpsc368,cpsc). prereqs(cpsc368,[cpsc203,cpsc210,cpen221]).
named(cpsc402,"cpsc402"). course(cpsc402). credits(cpsc402,3). in_dept(cpsc402,cpsc). prereqs(cpsc402,[cpsc302,cpsc303,math307]).
named(cpsc404,"cpsc404"). course(cpsc404). credits(cpsc404,3). in_dept(cpsc404,cpsc).
named(cpsc406,"cpsc406"). course(cpsc406). credits(cpsc406,3). in_dept(cpsc406,cpsc). prereqs(cpsc406,[cpsc302,cpsc303,math307]).
named(cpsc410,"cpsc410"). course(cpsc410). credits(cpsc410,3). in_dept(cpsc410,cpsc).
named(cpsc411,"cpsc411"). course(cpsc411). credits(cpsc411,3). in_dept(cpsc411,cpsc). prereqs(cpsc411,[cpsc213,cpsc221,cpsc311]).
named(cpsc416,"cpsc416"). course(cpsc416). credits(cpsc416,3). in_dept(cpsc416,cpsc). prereqs(cpsc416,[cpsc313,cpen331,cpsc317,elec331]).
named(cpsc418,"cpsc418"). course(cpsc418). credits(cpsc418,3). in_dept(cpsc418,cpsc).
named(cpsc420,"cpsc420"). course(cpsc420). credits(cpsc420,3). in_dept(cpsc420,cpsc).
named(cpsc421,"cpsc421"). course(cpsc421). credits(cpsc421,3). in_dept(cpsc421,cpsc).
named(cpsc422,"cpsc422"). course(cpsc422). credits(cpsc422,3). in_dept(cpsc422,cpsc).
named(cpsc424,"cpsc424"). course(cpsc424). credits(cpsc424,3). in_dept(cpsc424,cpsc).
named(cpsc425,"cpsc425"). course(cpsc425). credits(cpsc425,3). in_dept(cpsc425,cpsc). prereqs(cpsc425,[cpsc221,math200,math221]).
named(cpsc430,"cpsc430"). course(cpsc430). credits(cpsc430,3). in_dept(cpsc430,cpsc).
named(cpsc436a,"cpsc436a"). course(cpsc436a). credits(cpsc436a,3). in_dept(cpsc436a,cpsc).
named(cpsc436n,"cpsc436n"). course(cpsc436n). credits(cpsc436n,3). in_dept(cpsc436n,cpsc).
named(cpsc436r,"cpsc436r"). course(cpsc436r). credits(cpsc436r,3). in_dept(cpsc436r,cpsc).
named(cpsc440,"cpsc440"). course(cpsc440). credits(cpsc440,3). in_dept(cpsc440,cpsc). prereqs(cpsc440,[cpsc320,cpsc340]).
named(cpsc444,"cpsc444"). course(cpsc444). credits(cpsc444,3). in_dept(cpsc444,cpsc).
named(cpsc445,"cpsc445"). course(cpsc445). credits(cpsc445,3). in_dept(cpsc445,cpsc).
named(cpsc447,"cpsc447"). course(cpsc447). credits(cpsc447,3). in_dept(cpsc447,cpsc). prereqs(cpsc447,[cpsc310,cpen321]).
named(cpsc448a,"cpsc448a"). course(cpsc448a). credits(cpsc448a,3). in_dept(cpsc448a,cpsc).
named(cpsc448b,"cpsc448b"). course(cpsc448b). credits(cpsc448b,3). in_dept(cpsc448b,cpsc).
named(cpsc448c,"cpsc448c"). course(cpsc448c). credits(cpsc448c,6). in_dept(cpsc448c,cpsc).
named(cpsc449,"cpsc449"). course(cpsc449). credits(cpsc449,6). in_dept(cpsc449,cpsc).
named(cpsc490a,"cpsc490a"). course(cpsc490a). credits(cpsc490a,3). in_dept(cpsc490a,cpsc).
named(cpsc491,"cpsc491"). course(cpsc491). credits(cpsc491,6). in_dept(cpsc491,cpsc).
named(econ101,"econ101"). course(econ101). credits(econ101,3). in_dept(econ101,econ).
named(econ102,"econ102"). course(econ102). credits(econ102,3). in_dept(econ102,econ).
named(econ221,"econ221"). course(econ221). credits(econ221,3). in_dept(econ221,econ). prereqs(econ221,[econ101,econ102]).
named(econ226,"econ226"). course(econ226). credits(econ226,3). in_dept(econ226,econ). prereqs(econ226,[econ101,econ102]).
named(econ234,"econ234"). course(econ234). credits(econ234,3). in_dept(econ234,econ). prereqs(econ234,[econ101,econ102]).
named(econ255,"econ255"). course(econ255). credits(econ255,3). in_dept(econ255,econ). prereqs(econ255,[econ101,econ102]).
named(econ301,"econ301"). course(econ301). credits(econ301,3). in_dept(econ301,econ).
named(econ302,"econ302"). course(econ302). credits(econ302,3). in_dept(econ302,econ).
named(econ303,"econ303"). course(econ303). credits(econ303,3). in_dept(econ303,econ). prereqs(econ303,[econ301,econ304]).
named(econ304,"econ304"). course(econ304). credits(econ304,3). in_dept(econ304,econ).
named(econ305,"econ305"). course(econ305). credits(econ305,3). in_dept(econ305,econ).
named(econ306,"econ306"). course(econ306). credits(econ306,3). in_dept(econ306,econ).
named(econ307,"econ307"). course(econ307). credits(econ307,3). in_dept(econ307,econ).
named(econ309,"econ309"). course(econ309). credits(econ309,3). in_dept(econ309,econ).
named(econ310,"econ310"). course(econ310). credits(econ310,3). in_dept(econ310,econ).
named(econ311,"econ311"). course(econ311). credits(econ311,3). in_dept(econ311,econ).
named(econ315,"econ315"). course(econ315). credits(econ315,3). in_dept(econ315,econ).
named(econ316,"econ316"). course(econ316). credits(econ316,3). in_dept(econ316,econ). prereqs(econ316,[econ301,econ304,econ315]).
named(econ317,"econ317"). course(econ317). credits(econ317,3). in_dept(econ317,econ). prereqs(econ317,[econ101,econ102]).
named(econ319,"econ319"). course(econ319). credits(econ319,3). in_dept(econ319,econ). prereqs(econ319,[econ101,econ102]).
named(econ323,"econ323"). course(econ323). credits(econ323,3). in_dept(econ323,econ).
named(econ325,"econ325"). course(econ325). credits(econ325,3). in_dept(econ325,econ).
named(econ326,"econ326"). course(econ326). credits(econ326,3). in_dept(econ326,econ). prereqs(econ326,[econ325,econ327]).
named(econ327,"econ327"). course(econ327). credits(econ327,3). in_dept(econ327,econ).
named(econ328,"econ328"). course(econ328). credits(econ328,3). in_dept(econ328,econ). prereqs(econ328,[econ325,econ327]).
named(econ334,"econ334"). course(econ334). credits(econ334,3). in_dept(econ334,econ). prereqs(econ334,[econ101,econ102]).
named(econ335,"econ335"). course(econ335). credits(econ335,3). in_dept(econ335,econ). prereqs(econ335,[econ101,econ102]).
named(econ336,"econ336"). course(econ336). credits(econ336,3). in_dept(econ336,econ). prereqs(econ336,[econ101,econ102]).
named(econ339,"econ339"). course(econ339). credits(econ339,3). in_dept(econ339,econ). prereqs(econ339,[econ101,econ102]).
named(econ345,"econ345"). course(econ345). credits(econ345,3). in_dept(econ345,econ). prereqs(econ345,[econ101,econ102]).
named(econ350,"econ350"). course(econ350). credits(econ350,3). in_dept(econ350,econ). prereqs(econ350,[econ101,econ102]).
named(econ351,"econ351"). course(econ351). credits(econ351,3). in_dept(econ351,econ). prereqs(econ351,[econ101,econ102]).
named(econ355,"econ355"). course(econ355). credits(econ355,3). in_dept(econ355,econ). prereqs(econ355,[econ101,econ102]).
named(econ356,"econ356"). course(econ356). credits(econ356,3). in_dept(econ356,econ). prereqs(econ356,[econ101,econ102]).
named(econ364a,"econ364a"). course(econ364a). credits(econ364a,3). in_dept(econ364a,econ).
named(econ370,"econ370"). course(econ370). credits(econ370,3). in_dept(econ370,econ). prereqs(econ370,[econ101,econ102]).
named(econ371,"econ371"). course(econ371). credits(econ371,3). in_dept(econ371,econ). prereqs(econ371,[econ101,econ102]).
named(econ374,"econ374"). course(econ374). credits(econ374,3). in_dept(econ374,econ). prereqs(econ374,[econ101,econ102]).
named(econ390,"econ390"). course(econ390). credits(econ390,3). in_dept(econ390,econ).
named(econ398,"econ398"). course(econ398). credits(econ398,3). in_dept(econ398,econ).
named(econ407,"econ407"). course(econ407). credits(econ407,3). in_dept(econ407,econ). prereqs(econ407,[econ301,econ304,econ302,econ305,econ303,econ306]).
named(econ420,"econ420"). course(econ420). credits(econ420,3). in_dept(econ420,econ).
named(econ421,"econ421"). course(econ421). credits(econ421,3). in_dept(econ421,econ). prereqs(econ421,[econ301,econ304,econ315]).
named(econ425,"econ425"). course(econ425). credits(econ425,3). in_dept(econ425,econ). prereqs(econ425,[econ325,econ327,econ326,econ328]).
named(econ441,"econ441"). course(econ441). credits(econ441,3). in_dept(econ441,econ). prereqs(econ441,[econ301,econ304,econ315]).
named(econ442,"econ442"). course(econ442). credits(econ442,3). in_dept(econ442,econ). prereqs(econ442,[econ301,econ304,econ315]).
named(econ450,"econ450"). course(econ450). credits(econ450,3). in_dept(econ450,econ). prereqs(econ450,[econ301,econ304,econ315]).
named(econ455,"econ455"). course(econ455). credits(econ455,3). in_dept(econ455,econ). prereqs(econ455,[econ301,econ304,econ315]).
named(econ456,"econ456"). course(econ456). credits(econ456,3). in_dept(econ456,econ). prereqs(econ456,[econ302,econ305,econ309]).
named(econ457,"econ457"). course(econ457). credits(econ457,3). in_dept(econ457,econ). prereqs(econ457,[econ101,econ102]).
named(econ460,"econ460"). course(econ460). credits(econ460,3). in_dept(econ460,econ). prereqs(econ460,[econ301,econ304,econ315,econ302,econ305,econ309]).
named(econ471,"econ471"). course(econ471). credits(econ471,3). in_dept(econ471,econ). prereqs(econ471,[econ301,econ304,econ315]).
named(econ485,"econ485"). course(econ485). credits(econ485,3). in_dept(econ485,econ). prereqs(econ485,[econ301,econ304,econ315,econ302,econ305,econ309,econ325,econ327,econ326,econ328]).
named(econ490,"econ490"). course(econ490). credits(econ490,3). in_dept(econ490,econ).
named(econ492f,"econ492f"). course(econ492f). credits(econ492f,3). in_dept(econ492f,econ).
named(econ493,"econ493"). course(econ493). credits(econ493,3). in_dept(econ493,econ).
named(econ494,"econ494"). course(econ494). credits(econ494,3). in_dept(econ494,econ).
named(econ495,"econ495"). course(econ495). credits(econ495,3). in_dept(econ495,econ).
named(econ499,"econ499"). course(econ499). credits(econ499,6). in_dept(econ499,econ).
named(math100,"math100"). course(math100). credits(math100,3). in_dept(math100,math).
named(math101,"math101"). course(math101). credits(math101,3). in_dept(math101,math). prereqs(math101,[math100,math102,math104,math110,math120,math180,math184]).
named(math110,"math110"). course(math110). credits(math110,6). in_dept(math110,math).
named(math120,"math120"). course(math120). credits(math120,4). in_dept(math120,math).
named(math121,"math121"). course(math121). credits(math121,4). in_dept(math121,math).
named(math152,"math152"). course(math152). credits(math152,3). in_dept(math152,math).
named(math180,"math180"). course(math180). credits(math180,4). in_dept(math180,math).
named(math190,"math190"). course(math190). credits(math190,4). in_dept(math190,math).
named(math200,"math200"). course(math200). credits(math200,3). in_dept(math200,math). prereqs(math200,[math101,math103,math105,math121,scie001]).
named(math210,"math210"). course(math210). credits(math210,3). in_dept(math210,math). prereqs(math210,[math101,math103,math105,math121,scie001]).
named(math215,"math215"). course(math215). credits(math215,3). in_dept(math215,math). prereqs(math215,[math101,math103,math105,math121,scie001,math152,math221,math223]).
named(math217,"math217"). course(math217). credits(math217,4). in_dept(math217,math).
named(math220,"math220"). course(math220). credits(math220,3). in_dept(math220,math).
named(math221,"math221"). course(math221). credits(math221,3). in_dept(math221,math).
named(math223,"math223"). course(math223). credits(math223,3). in_dept(math223,math).
named(math226,"math226"). course(math226). credits(math226,3). in_dept(math226,math).
named(math227,"math227"). course(math227). credits(math227,3). in_dept(math227,math).
named(math253,"math253"). course(math253). credits(math253,3). in_dept(math253,math). prereqs(math253,[math101,math103,math105,math121,scie001]).
named(math254,"math254"). course(math254). credits(math254,3). in_dept(math254,math).
named(math255,"math255"). course(math255). credits(math255,3). in_dept(math255,math). prereqs(math255,[math101,math103,math105,math121,scie001,math152,math221,math223]).
named(math256,"math256"). course(math256). credits(math256,3). in_dept(math256,math). prereqs(math256,[math101,math103,math105,math121,scie001,math152,math221,math223]).
named(math257,"math257"). course(math257). credits(math257,3). in_dept(math257,math). prereqs(math257,[math215,math255,math256,math258]).
named(math258,"math258"). course(math258). credits(math258,3). in_dept(math258,math).
named(math264,"math264"). course(math264). credits(math264,1). in_dept(math264,math). prereqs(math264,[math200,math217,math226,math253,math254]).
named(math300,"math300"). course(math300). credits(math300,3). in_dept(math300,math). prereqs(math300,[math200,math217,math226,math253,math254]).
named(math301,"math301"). course(math301). credits(math301,3). in_dept(math301,math). prereqs(math301,[math300,math305,math215,math255,math256,math258]).
named(math302,"math302"). course(math302). credits(math302,3). in_dept(math302,math). prereqs(math302,[math200,math217,math226,math253,math254]).
named(math303,"math303"). course(math303). credits(math303,3). in_dept(math303,math). prereqs(math303,[math302,stat302]).
named(math305,"math305"). course(math305). credits(math305,3). in_dept(math305,math). prereqs(math305,[math200,math217,math226,math253,math254,math215,math255,math256,math258]).
named(math307,"math307"). course(math307). credits(math307,3). in_dept(math307,math). prereqs(math307,[math152,math221,math223,math200,math217,math226,math253,math254]).
named(math309,"math309"). course(math309). credits(math309,3). in_dept(math309,math).
named(math312,"math312"). course(math312). credits(math312,3). in_dept(math312,math).
named(math316,"math316"). course(math316). credits(math316,3). in_dept(math316,math). prereqs(math316,[math215,math255,math256,math258]).
named(math317,"math317"). course(math317). credits(math317,3). in_dept(math317,math). prereqs(math317,[math200,math226,math253,math152,math221,math223]).
named(math318,"math318"). course(math318). credits(math318,3). in_dept(math318,math). prereqs(math318,[math152,math221,math223,math215,math255,math256,math258]).
named(math319,"math319"). course(math319). credits(math319,3). in_dept(math319,math).
named(math320,"math320"). course(math320). credits(math320,3). in_dept(math320,math).
named(math321,"math321"). course(math321). credits(math321,3). in_dept(math321,math).
named(math322,"math322"). course(math322). credits(math322,3). in_dept(math322,math).
named(math323,"math323"). course(math323). credits(math323,3). in_dept(math323,math).
named(math335,"math335"). course(math335). credits(math335,4). in_dept(math335,math).
named(math340,"math340"). course(math340). credits(math340,3). in_dept(math340,math). prereqs(math340,[math152,math221,math223]).
named(math341,"math341"). course(math341). credits(math341,3). in_dept(math341,math). prereqs(math341,[math220,math223,math226,cpsc121]).
named(math342,"math342"). course(math342). credits(math342,3). in_dept(math342,math).
named(math344,"math344"). course(math344). credits(math344,3). in_dept(math344,math).
named(math358,"math358"). course(math358). credits(math358,3). in_dept(math358,math). prereqs(math358,[mech224,mech225]).
named(math361,"math361"). course(math361). credits(math361,3). in_dept(math361,math). prereqs(math361,[biol301,math215,math255,math256,math258]).
named(math400,"math400"). course(math400). credits(math400,3). in_dept(math400,math). prereqs(math400,[math300,math305,math256,math257,math316,math358,mech358,phys312]).
named(math401,"math401"). course(math401). credits(math401,3). in_dept(math401,math).
named(math404,"math404"). course(math404). credits(math404,3). in_dept(math404,math).
named(math405,"math405"). course(math405). credits(math405,3). in_dept(math405,math). prereqs(math405,[math256,math257,math316,math358,mech358,phys312]).
named(math406,"math406"). course(math406). credits(math406,3). in_dept(math406,math).
named(math412,"math412"). course(math412). credits(math412,3). in_dept(math412,math).
named(math418,"math418"). course(math418). credits(math418,3). in_dept(math418,math).
named(math419,"math419"). course(math419). credits(math419,3). in_dept(math419,math).
named(math420,"math420"). course(math420). credits(math420,3). in_dept(math420,math).
named(math421,"math421"). course(math421). credits(math421,3). in_dept(math421,math).
named(math422,"math422"). course(math422). credits(math422,3). in_dept(math422,math).
named(math423,"math423"). course(math423). credits(math423,3). in_dept(math423,math).
named(math424,"math424"). course(math424). credits(math424,3). in_dept(math424,math).
named(math425,"math425"). course(math425). credits(math425,3). in_dept(math425,math). prereqs(math425,[math221,math223,math217,math227,math254,math264,math317,math319,math320]).
named(math426,"math426"). course(math426). credits(math426,3). in_dept(math426,math).
named(math427,"math427"). course(math427). credits(math427,3). in_dept(math427,math).
named(math437,"math437"). course(math437). credits(math437,3). in_dept(math437,math).
named(math440,"math440"). course(math440). credits(math440,3). in_dept(math440,math).
named(math441,"math441"). course(math441). credits(math441,3). in_dept(math441,math).
named(math442,"math442"). course(math442). credits(math442,3). in_dept(math442,math).
named(math443,"math443"). course(math443). credits(math443,3). in_dept(math443,math).
named(math444,"math444"). course(math444). credits(math444,3). in_dept(math444,math).
named(math446,"math446"). course(math446). credits(math446,3). in_dept(math446,math).
named(math449d,"math449d"). course(math449d). credits(math449d,3). in_dept(math449d,math).
named(math450,"math450"). course(math450). credits(math450,3). in_dept(math450,math).
named(math462,"math462"). course(math462). credits(math462,3). in_dept(math462,math). prereqs(math462,[math361,math345]).
named(phys100,"phys100"). course(phys100). credits(phys100,3). in_dept(phys100,phys).
named(phys106,"phys106"). course(phys106). credits(phys106,3). in_dept(phys106,phys).
named(phys108,"phys108"). course(phys108). credits(phys108,3). in_dept(phys108,phys).
named(phys117,"phys117"). course(phys117). credits(phys117,3). in_dept(phys117,phys). prereqs(phys117,[phys100]).
named(phys118,"phys118"). course(phys118). credits(phys118,3). in_dept(phys118,phys). prereqs(phys118,[phys101,phys106,phys107,phys117,phys131,phys157,math100,math102,math104,math110,math120,math180,math184]).
named(phys119,"phys119"). course(phys119). credits(phys119,1). in_dept(phys119,phys). prereqs(phys119,[phys100]).
named(phys129,"phys129"). course(phys129). credits(phys129,1). in_dept(phys129,phys). prereqs(phys129,[phys107,phys119]).
named(phys131,"phys131"). course(phys131). credits(phys131,3). in_dept(phys131,phys). prereqs(phys131,[phys100]).
named(phys157,"phys157"). course(phys157). credits(phys157,3). in_dept(phys157,phys). prereqs(phys157,[phys100]).
named(phys158,"phys158"). course(phys158). credits(phys158,3). in_dept(phys158,phys).
named(phys159,"phys159"). course(phys159). credits(phys159,1). in_dept(phys159,phys). prereqs(phys159,[phys100]).
named(phys170,"phys170"). course(phys170). credits(phys170,3). in_dept(phys170,phys). prereqs(phys170,[phys100,math100,math102,math104,math110,math120,math180,math184]).
named(phys200,"phys200"). course(phys200). credits(phys200,4). in_dept(phys200,phys).
named(phys203,"phys203"). course(phys203). credits(phys203,4). in_dept(phys203,phys). prereqs(phys203,[phys102,phys108,phys118,phys158,phys153,scie001]).
named(phys210,"phys210"). course(phys210). credits(phys210,3). in_dept(phys210,phys). prereqs(phys210,[phys102,phys108,phys118,phys158,phys153,scie001]).
named(phys216,"phys216"). course(phys216). credits(phys216,3). in_dept(phys216,phys). prereqs(phys216,[phys106,phys107,phys117,phys170,scie001,math152,math221,math223]).
named(phys219,"phys219"). course(phys219). credits(phys219,2). in_dept(phys219,phys).
named(phys229,"phys229"). course(phys229). credits(phys229,1). in_dept(phys229,phys).
named(phys298,"phys298"). course(phys298). credits(phys298,3). in_dept(phys298,phys).
named(phys299,"phys299"). course(phys299). credits(phys299,3). in_dept(phys299,phys).
named(phys301,"phys301"). course(phys301). credits(phys301,3). in_dept(phys301,phys). prereqs(phys301,[phys102,phys108,phys118,phys153,phys158,scie001,math217,math227,math317,math215,math255]).
named(phys304,"phys304"). course(phys304). credits(phys304,3). in_dept(phys304,phys). prereqs(phys304,[phys200,phys250]).
named(phys305,"phys305"). course(phys305). credits(phys305,3). in_dept(phys305,phys).
named(phys306,"phys306"). course(phys306). credits(phys306,3). in_dept(phys306,phys). prereqs(phys306,[phys216,enph270,math215,math255,math256,math258]).
named(phys309,"phys309"). course(phys309). credits(phys309,3). in_dept(phys309,phys). prereqs(phys309,[phys209,phys229,enph259]).
named(phys312,"phys312"). course(phys312). credits(phys312,3). in_dept(phys312,phys).
named(phys319,"phys319"). course(phys319). credits(phys319,3). in_dept(phys319,phys). prereqs(phys319,[phys209,phys219,enph259]).
named(phys333,"phys333"). course(phys333). credits(phys333,3). in_dept(phys333,phys).
named(phys341,"phys341"). course(phys341). credits(phys341,3). in_dept(phys341,phys).
named(phys348,"phys348"). course(phys348). credits(phys348,3). in_dept(phys348,phys).
named(phys349,"phys349"). course(phys349). credits(phys349,3). in_dept(phys349,phys).
named(phys350,"phys350"). course(phys350). credits(phys350,3). in_dept(phys350,phys). prereqs(phys350,[enph270,phys270]).
named(phys399,"phys399"). course(phys399). credits(phys399,3). in_dept(phys399,phys).
named(phys400,"phys400"). course(phys400). credits(phys400,3). in_dept(phys400,phys). prereqs(phys400,[phys304,phys450]).
named(phys401,"phys401"). course(phys401). credits(phys401,3). in_dept(phys401,phys). prereqs(phys401,[phys301,phys354]).
named(phys402,"phys402"). course(phys402). credits(phys402,3). in_dept(phys402,phys). prereqs(phys402,[phys304,phys450]).
named(phys403,"phys403"). course(phys403). credits(phys403,3). in_dept(phys403,phys). prereqs(phys403,[phys203,enph257,phys257,chem201,chem304,phys304,phys450,chem312,math302,math318,stat241,stat251,stat302]).
named(phys404,"phys404"). course(phys404). credits(phys404,3). in_dept(phys404,phys).
named(phys405,"phys405"). course(phys405). credits(phys405,3). in_dept(phys405,phys).
named(phys407,"phys407"). course(phys407). credits(phys407,3). in_dept(phys407,phys). prereqs(phys407,[math217,math227,math317,math215,math255,phys301,phys206,phys306]).
named(phys408,"phys408"). course(phys408). credits(phys408,4). in_dept(phys408,phys). prereqs(phys408,[phys301,phys354,math215,math255]).
named(phys409a,"phys409a"). course(phys409a). credits(phys409a,3). in_dept(phys409a,phys). prereqs(phys409a,[phys309,phys319]).
named(phys409b,"phys409b"). course(phys409b). credits(phys409b,3). in_dept(phys409b,phys). prereqs(phys409b,[phys309,phys319]).
named(phys410,"phys410"). course(phys410). credits(phys410,3). in_dept(phys410,phys). prereqs(phys410,[phys312,math257,math316,phys210,eosc211,cpsc110,cpsc103,apsc160]).
named(phys420c,"phys420c"). course(phys420c). credits(phys420c,3). in_dept(phys420c,phys).
named(phys438,"phys438"). course(phys438). credits(phys438,3). in_dept(phys438,phys). prereqs(phys438,[phys101,phys106,phys107,phys117,phys131,phys157,scie001,biol325]).
named(phys447a,"phys447a"). course(phys447a). credits(phys447a,3). in_dept(phys447a,phys).
named(phys447b,"phys447b"). course(phys447b). credits(phys447b,3). in_dept(phys447b,phys).
named(phys447c,"phys447c"). course(phys447c). credits(phys447c,6). in_dept(phys447c,phys).
named(phys449,"phys449"). course(phys449). credits(phys449,6). in_dept(phys449,phys).
named(phys473,"phys473"). course(phys473). credits(phys473,3). in_dept(phys473,phys). prereqs(phys473,[phys304,phys450]).
named(phys474,"phys474"). course(phys474). credits(phys474,3). in_dept(phys474,phys). prereqs(phys474,[phys450,phys304]).
named(phys490,"phys490"). course(phys490). credits(phys490,3). in_dept(phys490,phys).
named(phys498,"phys498"). course(phys498). credits(phys498,3). in_dept(phys498,phys).
named(phys499,"phys499"). course(phys499). credits(phys499,3). in_dept(phys499,phys).
