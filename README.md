# UBC course scheduler in Prolog

## Setup Instruction
what you need is only SWIPL
- you can download from [here](https://www.swi-prolog.org/download/stable)

## how to start
1. run

    ```swipl -s main.pl ```
2. then, access to `localhost:8000`

## how to run test
1. run

    ```swipl test.pl```

## What we have done
- Web app for the ubc student to get the shchedule based on their requests
- The standard form enable us to select the numeber of credits, the courses and numbers and the timeslot when you don't want to have classes.
- The app will show the recommended schedule and you can see all.

## Future Work
- Support more facts (add more course facts).
- Support the laboratory or tutorial session.
- Support the flexible timespan for the class such that it does not have the same start time of the lecture.
  - e.g. Monday 15:00 - 17:00, Thursday 9:00 - 10:00
- Add the weight on the each course facts based on the user status then sort the recommended schedule by the score of each.

- Improve the web natural language interface
- Added more natural language expressions to allow for more flexible nl queries

- Change course and section facts to allow for more efficient filtering
