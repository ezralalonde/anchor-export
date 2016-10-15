# anchor-export

A small utility for exporting posts and pages from AnchorCMS.

## Problem

You have been using AnchorCMS with MySQL for a while, and have a
bunch of pages and posts. You need to be able to export the data into static
text files, either for backup, or for importing into another system.

## Solution

Run this bash script. It will export all `posts` and `pages` in
your MySQL database to [Markdown](https://en.wikipedia.org/wiki/Markdown)
files with a [TOML](hettps://github.com/toml-lang/toml) header suitable for
use with
[Phenomic](https://github.com/MoOx/phenomic),
[Hugo](https://gohugo.io),
[Jekyll](https://jekyllrb.com/),
etc.

Filenames are base on the `slug` of the page.

## Limitations

* It doesn't currently export `css` or `js`.
* It doesn't currently include all metadata.

## Usage


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

## Bonus

* Uses PHP to reverse HTML Encoding of characters (ie. `&lt;` becomes `<`).
* Asks for confirmation before deleting directories by default.

It should be pretty easy to hack on to suit your requirements.
