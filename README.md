# Moodle tools

Automate various teaching actions in the Moodle of the university of Lübeck.

Almost all scripts take these environment variables as input: 

    course   Course id
    section  Weekly section in the course 
    user     Username
    pass     Password

## Examples

Upload file "exercises.pdf" with title "Exercise Sheet":

    name="Exercise Sheet" description="Exercise Sheet" ./upload.sh exercises.pdf

Create a heading in a course:

    description="<h5>Some heading text</h5>" descriptionformat=html ./add.sh label showdescription=1

The examples assume the above environment variables have been set, so it knows in which course the content should be created.

## Installation

You only need bash and Xidel >= 0.9.9 installed. 

The scripts can then be called without installation.

Xidel is searched as `~/xidel`. You can edit `common.sh` to adjust this and other configuration.

## Available scripts


### add.sh

 Adds something to a moodle course

     Input as environment variables and parameters
       course
       section
       name
       description       -> long description
       descriptionformat -> format as you can choose in the Moodle: html, moodle, markdown, text
       $1                -> the thing to add
                            e.g. label, url, page, etherpadlite, moodleoverflow
       $2                -> additional options (url encoded or JSON)


### addurl.sh

 Adds a link to $1

     Input as environment variables and parameters
       course
       section
       name
       description   -> long description
       descriptionformat -> format as you can choose in the Moodle: html, moodle, markdown, text
       $1            -> link target
       $2            -> additional options (url encoded or JSON)


### common.sh

Loads the moodle configuration, user and password, xidel path. Used internally by every other script



### forumpost.sh

Post message STDIN to forum $1

    $1 is the forum post id not the id from the forum view url. (look at the hidden input with name "forum" in the form code of the forum)
    options: 
      $2             -> subject
      $3             -> additional options (url encoded or JSON)
      messageformat


### getstudents.sh

 Downloads the list of students from a course

     Input as environment variable
       course


### getsubmissions.sh

 Downloads submissions from an assignment

     Input as environment variables
       exercise      Assignment id
    
    Im Moodle muss die Zahl der angezeigten Abgaben auf 100 gesetzt werden (oder die Zahl der Studenten), da nur die erste Seite heruntergeladen wird.


### groupgrading/mergegradedandduplicates.sh

Create a "merged" subdirectory containing:

      all files of the current directory
      all files removed by moveduplicates.sh, but replaced by the file that has replaced the duplicate in the current dir (assuming all duplicates are named GROUP...-). 


### groupgrading/moveduplicates.sh

Move duplicated files in the current directory to a "duplicates" subdirectory



### hideactivities.sh

 Hides some activities

     Input as environment variables and parameters
       course
       $1      title of activities to hide


### hideslides.sh

 Hides activities with caption "Vorlesungsfolien"

     Input as environment variables
       course


### hideweeks.sh

 Hides week section

     Input as environment variables and parameters
       course
       $1 to  $2    section numbers to hide


### makeassignment.sh

Makes an assignment

    Input:
      environment variables:
         course
         section
      stdin:
         parameters
         (see modifyassignment)


### makeformula.sh

 Create a grading formula for a course. Condition: pass if at most two exercise assignments were failed.

     Input as environment variable
       course


### message.sh

Call it with message.sh userid "message" to send a message to someone



### messagelogins.sh

Message login data to multiple people



### modifyassignment.sh

Input on stdin

    
      keys to change  (in JSON/XQuery, without surrounding {})
      urls to exercises
    
    important keys:
    
    "duedate", "allowsubmissionsfromdate", "cutoffdate"
    "assignsubmission_file_enabled": 1
    "sendnotifications":  0, 1
    
    ------------------
    Example to shift exercises from one year to the next:
    "alldates": xs:dayTimeDuration("P364D"), 
    "assignsubmission_file_enabled": 1,
    "sendnotifications":  0
    
    https://moodle.uni-luebeck.de/course/modedit.php?update=112042&return=1
    https://moodle.uni-luebeck.de/course/modedit.php?update=112057&return=1
    https://moodle.uni-luebeck.de/course/modedit.php?update=112070&return=1
    https://moodle.uni-luebeck.de/course/modedit.php?update=112077&return=1
    https://moodle.uni-luebeck.de/course/modedit.php?update=112087&return=1
    https://moodle.uni-luebeck.de/course/modedit.php?update=112117&return=1
    https://moodle.uni-luebeck.de/course/modedit.php?update=112127&return=1
    https://moodle.uni-luebeck.de/course/modedit.php?update=112135&return=1
    https://moodle.uni-luebeck.de/course/modedit.php?update=112143&return=1
    
    ----------------------


### moodleupload.sh

Upload a (TCS) exercise sheet given as tex file to the moodle course and create assignment/VPLs

    Input as environment variable
      $1        tex file (if absent use random tex file from current directory)
      course    (if absent read from tex file)


### nukeit.sh

 Deletes everything from a course

       course


### removeduedate.sh

 Removes the duedate from an exercise with id $exercise



### semesterdates.sh

 Reads the start and end dates for the semesters of this year from the university of Lübeck webpage.

     Also reads holidays.


### setsectioninfo.sh

 Sets text of section $section

     Input as environment variables and parameters
       course
       section
       name
       description
       descriptionformat


### setsectiontitles.sh

 Sets the titles of the sections of a course.

     Input as environment variables and parameters
       course
       section  Starting section (default 1)
       stdin    New titles 


### setupvpl.sh

 Creates or changes a VPL. 

     Input as environment variables and parameters
       course
       section
       name
       description
       $1            -> filename
       $2            -> additional assignment options


### showweeks.sh

 Shows the title of the weeks in a course

     Input as environment variables and parameters
        course
        $1     start week
        $2     end week


### upload.sh

 Uploads a file to a moodle course. 

     Input as environment variables and parameters
       course
       section
       name
       description
       folderid                if uploading to an existing folder
       $1            -> filename


