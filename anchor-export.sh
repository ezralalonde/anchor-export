#! /usr/bin/sh

LANG=en_CA.UTF-8
LANGUAGE=en_CA.UTF-8
LC_CTYPE="en_CA.UTF-8"
LC_NUMERIC="en_CA.UTF-8"
LC_TIME="en_CA.UTF-8"
LC_COLLATE="en_CA.UTF-8"
LC_MONETARY="en_CA.UTF-8"
LC_MESSAGES="en_CA.UTF-8"
LC_PAPER="en_CA.UTF-8"
LC_NAME="en_CA.UTF-8"
LC_ADDRESS="en_CA.UTF-8"
LC_TELEPHONE="en_CA.UTF-8"
LC_MEASUREMENT="en_CA.UTF-8"
LC_IDENTIFICATION="en_CA.UTF-8"
LC_ALL=en_CA.UTF-8

# $1 = CONVERT FROM WINDOWS 1252 TO UTF-8
fix () {
	TEMP=$(mktemp)
	iconv -f windows-1252 -t utf-8 $1 > $TEMP
	mv $TEMP $1
}

# $1 = CONTENT TO HTML ESCAPE
clean () {
	echo -e "$1" |\
	tr -d '\r' |\
	php -r 'while(($line=fgets(STDIN)) !== FALSE) echo html_entity_decode($line, ENT_QUOTES|ENT_HTML401);'
}

# $1 = KEY
# $2 = VALUE
frontmatter () {
	echo "$1: \"$2\"" | awk '$1=$1' 
}

# $1 = QUERY
run_query () {
	mysql --user=$USER --host=$HOST --port=$PORT --password=$PASS $BASE --batch --skip-column-names -e "$1"
}

# $1 = INPUT FILE
slice_pages () {
	DIR="$DIRECTORY"/pages
	mkdir "$DIR"
	while IFS=$'\t' read -r id slug parent redirect title status type content
	do
		FILE="$DIR"/"$slug".md
		echo -n "Exporting $FILE... "
		echo "---" > $FILE
		frontmatter "title" "$title" >> $FILE
		frontmatter "type" "$type" >> $FILE
		frontmatter "status" "$status"  >> $FILE
		frontmatter "redirect" "$redirect"  >> $FILE
		frontmatter "parent" "$parent" >> $FILE
		echo -e "---\n" >> $FILE
		clean "$content" >> $FILE
		fix "$FILE"
		echo "Done."
	done < "$1"
}

# anchor.anchor_pages
#
#+--------------+--------------------------------------+------+-----+---------+----------------+
#| Field        | Type                                 | Null | Key | Default | Extra          |
#+--------------+--------------------------------------+------+-----+---------+----------------+
#| id           | int(6)                               | NO   | PRI | NULL    | auto_increment |
#| parent       | int(6)                               | NO   |     | NULL    |                |
#| slug         | varchar(150)                         | NO   | MUL | NULL    |                |
#| pagetype     | varchar(140)                         | NO   |     | all     |                |
#| name         | varchar(64)                          | NO   |     | NULL    |                |
#| title        | varchar(150)                         | NO   |     | NULL    |                |
#| markdown     | text                                 | YES  |     | NULL    |                |
#| html         | text                                 | NO   |     | NULL    |                |
#| status       | enum('draft','published','archived') | NO   | MUL | NULL    |                |
#| redirect     | text                                 | NO   |     | NULL    |                |
#| show_in_menu | tinyint(1)                           | NO   |     | NULL    |                |
#| menu_order   | int(4)                               | NO   |     | NULL    |                |
#+--------------+--------------------------------------+------+-----+---------+----------------+
dump_pages () {
	TEMP=$(mktemp)
	echo -n "Dumping $USER@$HOST/$DATABASE.anchor_pages... "
	QUERY="
		SELECT
			IFNULL(ap.id, 'DEFAULT ID'),
			IFNULL(ap.slug, 'DEFAULT SLUG'),
			IFNULL(parent.slug, 'DEFAULT PARENT SLUG'),
			IF(ap.redirect IS NULL OR ap.redirect = '', 'DEFAULT REDIRECT', ap.redirect),
			COALESCE(ap.name, ap.title, 'DEFAULT TITLE'),
			IFNULL(ap.status, 'DEFAULT STATUS'),
			IFNULL(ap.pagetype, 'DEFAULT TYPE'),
			COALESCE(ap.markdown, ap.html, 'DEFAULT CONTENT'),
			''
		FROM anchor_pages as ap
		LEFT JOIN anchor_pages AS parent ON ap.parent = parent.id
	"
	run_query "$QUERY" > "$TEMP"
	echo "Done."

	slice_pages $TEMP
}

# $1 = INPUT FILE
slice_posts () {
	DIR="$DIRECTORY"/posts
	mkdir "$DIR"
	while IFS=$'\t' read -r id slug title status description category date author content
	do
		FILE="$DIR"/"${date%% *}-$slug".md
		echo -n "Exporting $FILE... "
		echo "---" > $FILE
		frontmatter "title" "$title" >> $FILE
		frontmatter "description" "$description" >> $FILE
		frontmatter "status" "$status" >> $FILE
		frontmatter "category" "$category" >> $FILE
		frontmatter "author" "$author" >> $FILE
		frontmatter "date" "${date%% *}" >> $FILE
		echo -e "---\n" >> $FILE
		clean "$content" >> $FILE
		fix "$FILE"
		echo "Done."
	done < "$1"

}

# anchor.anchor_posts
#
#+-------------+--------------------------------------+------+-----+---------+----------------+
#| Field       | Type                                 | Null | Key | Default | Extra          |
#+-------------+--------------------------------------+------+-----+---------+----------------+
#| id          | int(6)                               | NO   | PRI | NULL    | auto_increment |
#| title       | varchar(150)                         | NO   |     | NULL    |                |
#| slug        | varchar(150)                         | NO   | MUL | NULL    |                |
#| description | text                                 | NO   |     | NULL    |                |
#| markdown    | text                                 | NO   |     | NULL    |                |
#| html        | mediumtext                           | NO   |     | NULL    |                |
#| css         | text                                 | NO   |     | NULL    |                |
#| js          | text                                 | NO   |     | NULL    |                |
#| created     | datetime                             | NO   |     | NULL    |                |
#| author      | int(6)                               | NO   |     | NULL    |                |
#| category    | int(6)                               | NO   |     | NULL    |                |
#| status      | enum('draft','published','archived') | NO   | MUL | NULL    |                |
#| comments    | tinyint(1)                           | NO   |     | NULL    |                |
#+-------------+--------------------------------------+------+-----+---------+----------------+
dump_posts () {
	TEMP=$(mktemp)
	echo -n "Dumping $USER@$HOST/$DATABASE.anchor_posts "
	QUERY="
		SELECT
			IFNULL(ap.id, 'DEFAULT_ID'),
			IFNULL(ap.slug, 'DEFAULT_SLUG'),
			IFNULL(ap.title, 'DEFAULT_TITLE'),
			IFNULL(ap.status, 'DEFAULT_STATUS'),
			IF(ap.description IS NULL OR ap.description = '', 'DEFAULT DESCRIPTION', ap.description),
			IFNULL(category.slug, 'DEFAULT_CATEGORY'),
			IFNULL(ap.created, 'DEFAULT_CREATED'),
			IFNULL(author.real_name, 'DEFAULT_AUTHOR'),
			COALESCE(ap.markdown, ap.html, 'DEFAULT_CONTENT')
			''
		FROM anchor_posts as ap
		LEFT JOIN anchor_categories AS category ON ap.category = category.id
		LEFT JOIN anchor_users AS author ON ap.author = author.real_name
	"
	run_query "$QUERY" > "$TEMP"
	echo "Done."

	slice_posts $TEMP
}

dump_all() {
	dump_pages
	dump_posts
}

# $1 = directory to create
setdir () {
	if [ -e "$1" ] && [ -n "$1" ]
	then
		if [ -z "$FORCE" ]
		then
			read -r -p "File $1 exists. Overwrite? [y/N] " response
			response=${response,,}
		fi
		if [[ $response =~ ^(yes|y)$ ]] || [ -n "$FORCE" ]
		then
			echo -n "Deleting $1... "
			rm -rf "$1"		
			echo "Done."
		else
			echo "Doing nothing."
			exit 1
		fi
	fi

	echo -n "Creating $1... "
	mkdir "$1"
	echo "Done."
}

show_help () {
	echo <<-HELPTEXT
	Export Markdown files from AnchorCMS/MySQL database.

	Example usage:
	    anchor-export.sh --host=localhost --password=fake123 --user=ezralalonde --port=007 --output-dir=\./directory\
	    anchor-export.sh --openshift -o=out
	
	-h --host
	    MySQL database host.
	    Default: localhost
	-p --password
	    Password to the database.
	    Default: blank
	-d --database
	    The name of the AnchorCMS database.
	    Default: anchor
	-u --user
	    Name of the database user.
	    Default: root
	-P --port
	    Port to use to connect to database.
	    Default: 3306
	-o --output-dir	
	    Directory to output Markdown files into.
	    Will be created by the script. Do not use existing directory; it will be deleted.
	    Default: ./export
	--openshift	
	    Use environment variables to set other values.
	    USER=\$OPENSHIFT_MYSQL_DB_USERNAME
	    HOST=\$OPENSHIFT_MYSQL_DB_HOST
	    POST=\$OPENSHIFT_MYSQL_DB_PORT
	    PASS=\$OPENSHIFT_MYSQL_DB_PASSWORD
	HELPTEXT
}

DIRECTORY=./export
BASE=anchor
PORT=3306
USER=root
PASS=""
HOST="localhost"

for ii in "$@"
do
case $ii in
	-u=*|--user=*)
		USER="${ii#*=}"
		shift
	;;
	-P=*|--port=*)
		PORT="${ii#*=}"
		shift
	;;
	-h=*|--host=*)
		HOST="${ii#*=}"
		shift
	;;
	-p=*|--password=*)
		PASS="${ii#*=}"
		shift
	;;
	-d=*|--database=*)
		BASE="${ii#*=}"
		shift
	;;
	-o=*|--output-dir=*)
		DIRECTORY="${ii#*=}"
		shift
	;;
	--openshift)
		USER=$OPENSHIFT_MYSQL_DB_USERNAME
		HOST=$OPENSHIFT_MYSQL_DB_HOST
		POST=$OPENSHIFT_MYSQL_DB_PORT
		PASS=$OPENSHIFT_MYSQL_DB_PASSWORD
		shift
	;;
	-f|--force)
		FORCE=true
	;;
	-h|--help|*)
		show_help
		exit 0
	;;
esac
done

setdir $DIRECTORY
dump_all

