Templer
=======

Templer is yet another static site generator, written in Perl.

It makes use of the [HTML::Template](http://search.cpan.org/perldoc?HTML%3A%3ATemplate) module for performing variable expansion within pages and layouts, along with looping and conditional-statement handling.

Templer has evolved over time for my own personal use, but I believe
it is sufficiently generic it could be useful to others.

My motivation for putting it together came from the desire to change
several hand-made, HTML-coded, sites to something more maintainable such
that I could easily change the layout in one place.

The design evolved over time but the key reason for keeping it around
is that it differs from many other simple static-generators in several
ways:

* You may define global variables for use in your pages/layouts.
* A page may define and use page-specific variables.
* You may change the layout on a per-page basis if you so wish.
    * This was something that is missing from a lot of competing tools.
* Conditional variable expansion is supported, via `HTML::Template`.
* File contents, shell commands, and file-globs may be used in the templates
    * This allows the trivial creation of galleries, for example.
    * These are implemented via [plugins](#plugins).
* You may also embed perl code in your pages.

Another key point is that the layouts allow for more than a single
simple "content" block to be placed into them - you can add arbitrary
numbers of optional side-menus, for example.

Although this tool was written and used with the intent you'd write your
site-content in HTML you can write your input pages in Textile or Markdown
if you prefer (these inputs are supported via [plugins](#plugins)).


Concepts
--------

A templer site comprises of three things:

* A global configuration file.
     * This defines the paths to search for input pages, layout templates, plugins, etc.
     * This may contain global variable declarations.
     * Please see the example configuration file: [`templer.cfg`](https://raw.github.com/skx/templer/master/templer.cfg.sample).
* A layout.
    * This is used to format the output pages, defining the common look and feel.
* A series of pages & assets.
    * Pages have their content processed and inserted into the layout to produce output HTML.
    * Assets are not processed, but are copied into the output directory literally.

In general we assume there is a tree like so:

    ├── input
    │   ├── index.wgn
    │   ├── ...
    │   ├── ...
    │   ├── favicon.ico
    │   └── robots.txt
    ├── layouts
    │   └── default.layout
    ├── output
    └── templer.cfg

Every file in the input directory is either considered to be a page which is converted
into HTML, or an asset which is copied into the output-tree with no changes made.

In the example above `input/index.wgn` would become `output/index.html`.

> **NOTE** The `.wgn` suffix is an example. You can define which suffix is considered a page via the configuration file.

There is _also_ an "in-place" mode.  When working in-place there is no distinct output directory, instead output is written to the same directory in which is encountered.  Given an input directory you might see this kind of transformation:

     index.wgn           -> index.html
     about.wgn           -> about.html
     favicon.ico         [Ignored and left un-modified.]
     robots.txt          [Ignored and left un-modified.]
     ..



Pages
-----

Your site will be made of pages, which are snippets of HTML you write.  These
snippets will be processed and inserted into the layout file before being output
to disk.

A page is a simple file which contains a header and some content.  This is
a sample page:

    Title:  This is the title page.
    ----
    <p>This is the body of the page</p>


The header of the page is delimited from the body by four dashes (`----`) and can
contain an arbitrary number of variable definitions - although by default we'd only
expect to see the page title being set.

The special variable `layout` may be used to specify a different layout template for
the current page.  If there is no per-page layout specified then the global layout
declared in the `templer.cfg` file will be used.

The special variable 'output' may be used to specify an alternative output file.  For
example the input file `index.wgn` would normally become `index.html`, but you could make it become
something else.

The special variable `format` may be given a value of `textile` or `markdown` to
enable processing the page body with the appropriate filter.   These formatters are
implemented as [plugins](#plugins), and will be available assuming their
[dependencies are installed](#installation).

In addition to the `textile` and `markdown` formatters there is a `perl` formatter
available - providing the [Text::Template](http://search.cpan.org/perldoc?Text%3A%3ATemplate) module is installed - which allows Perl code to be executed, by wrapping it in `{` and `}` characters.  Here is a sample page:

    Title: This page has code in it
    format: perl
    ----

    <p>This page has some code in it.</p>
    <p>I am running on { `hostname` }...</p>
    <p>I am {
           my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
                                                               localtime(time);
           $year += 1900;
           $year - 1976;
       } years old.</p>



Variable Definitions
--------------------

Within the header of each page you may declare an arbitrary number of per-page
variables.  These variable declarations are then available for use within the
page-body, using the standard  [HTML::Template](http://search.cpan.org/perldoc?HTML%3A%3ATemplate) expansion facilities:


     Title:  Page title
     Name: Steve Kemp
     ----
     <p>Hello, my name is <!-- tmpl_var name='name' -->.</p>

> The only surprise here is that we referred to the variable called "Name" as "name".  All
variable-names are transformed to lower-case for consistency.

As well as simple "name: value" pairs there are also additional options:

* A variable may refer to the contents of a given file.
    * Using `read_file`.
* A variable may refer to a list of filenames, matching a pattern.
    * Using `file_glob`.
* A variable may contain the output of running a command.
    * Using `run_command`.

In addition to declaring variables in a page-header you may also declare
__global__ variables in your `templer.cfg` file.  This is demonstrated in
the sample [`templer.cfg`](https://raw.github.com/skx/templer/master/templer.cfg.sample) file.



File Globbing Variables
-----------------------

We've already seen simple variables declared by "key: value" in the page header,
in addition to this you may define a variable that refers to a number of files
by pattern.

Here is a simple example of creating a gallery which will include files matching
the pattern `img/*.jpg`:

     Title: My gallery
     Images: file_glob( "img/*.jpg" )
     ---
     <!-- tmpl_if name='images' -->
       <!-- tmpl_loop name='images' -->
        <p><img src="<!-- tmpl_var name='file' -->" /> </p>
       <!-- /tmpl_loop -->
     <!-- tmpl_else -->
       <p>No images were found.</p>
     <!-- /tmpl_if -->

> **TIP**:  If your images are numbered numerically you can ensure their correct order by doing this:

    Title:  This is my title
    images: file_glob( img/[0-9].jpg img/1[0-9].jpg )
    ----
    <p>My gallery is now included in ascending numerical order:</p>


This facility is implemented in the `Templer::Plugin::FileGlob` [plugin](#plugins).



File Inclusion
--------------

The [HTML::Template](http://search.cpan.org/perldoc?HTML%3A%3ATemplate) module supports file inclusion natively, via the following construct:

      <p>This is some text.</p>
      <!-- tmpl_include name='/etc/passwd' -->
      <p>That was my password file.</p>

In addition to this you may define a variable to contain the contents of a specified
file.  For example:

      Title: This file has my passwords!
      Passwd: read_file( "/etc/passwd" )
      ----
      <p>Please see my passwords:</p>
      <pre><!-- tmpl_var name='passwd' -->
      </pre>

This facility is implemented in the `Templer::Plugin::FileContents` [plugin](#plugins).

Included files, whether included via the `read_file` method, or via the native HTML::Template faclity, are searched for in the same fashion:

* If the filename is fully-qualified, then the absolute path-name will be used.
* Otherwise the include-path will be searched.
* After the include-path has been searched the file will be looked for in the location relative to the input page location.

This allows you to place all your include-files in a single directory which is outside your web-root.



Shell Command Execution
-----------------------

Pages may also define variables which receive the value of the output of shell commands.  This is done via definitions like this:


      Title: This file is dynamic
      Host: run_command( "hostname" )
      ----
      <p>This page was built upon <!-- tmpl_var name='host' -->.</p>

This facility is implemented in the `Templer::Plugin::ShellCommand` [plugin](#plugins).



Installation
------------

The code is modular and neat and is combined from a series of modules into a single script `templer`.  To install the tool system-wide run:

        $ git clone https://github.com/skx/templer.git
        $ cd templer
        $ sudo make install

(If you ever wish to remove the software you may run `sudo make uninstall`.)

If you wish to merely run/examine the scripts then you should run `make` first,
like so:

        $ git clone https://github.com/skx/templer.git
        $ cd templer
        $ make

This `make` (or `make default`) command is required to generate the script by concatenating the various modules which make up the code into a single script.  The code is deliberately contained in a single script to ease deployment, but developed in a modular fashion to ease testing.  (You can see a brief overview of [the logical structure](#object-hierarchy) later.)

The dependencies are minimal, to ease installation:

* Perl
* The [HTML::Template](http://search.cpan.org/perldoc?HTML%3A%3ATemplate) module.
   *  This may be installed, on a Debian system, with `apt-get install libhtml-template-perl`.
* The following are optional modules:
   * The [Image::Size](http://search.cpan.org/perldoc?Image%3A%3ASize) module is used if available whenever you create `file_glob`-using loops of image files.
      * This will set the attributes `width` and `height` any images added via `file_glob`.
   * The [Text::Markdown](http://search.cpan.org/perldoc?Text%3A%3AMarkdown) module is required if you wish to write your page bodies in Markdown.
      *  This may be installed, on a Debian system, with `apt-get install libtext-markdown-perl`.
   * The [Text::Textile](http://search.cpan.org/perldoc?Text%3A%3ATextile) module is required if you wish to write your page bodies in Textile.
      *  This may be installed, on a Debian system, with `apt-get install libtext-textile-perl`.
   * The [Text::Template](http://search.cpan.org/perldoc?Text%3A%3ATemplate) module is required if you wish to include dynamic perl in your input pages.
      *  This may be installed, on a Debian system, with `apt-get install libtext-template-perl`.


Creating a new site
-------------------

There is a supplied script `templer-generate` which will create a new site-structure
if you give in the name of a directory to create & write to:

     ~$ templer-generate my-site
     ~$ tree my-site/
     my-site/
      ├── include
      ├── input
      │   ├── about.wgn
      │   ├── index.wgn
      │   └── robots.txt
      ├── layouts
      │   └── default.layout
      ├── output
      └── templer.cfg

If you prefer you may go through the process manually creating a directory,
adding the [`templer.cfg`](https://raw.github.com/skx/templer/master/templer.cfg.sample)
to it, and then creating the input tree and layout directory.

There are two examples provided with the distribution to illustrate the
software.  These example sites are built automatically every evening and
uploaded online - so you may easily compare the input and the generated
output:

* [simple example source](https://github.com/skx/templer/tree/master/examples/simple)
   * The online [generated output](http://www.steve.org.uk/Software/templer/examples/simple/output/).
* [complex example source](https://github.com/skx/templer/tree/master/examples/complex)
   * The online [generated output](http://www.steve.org.uk/Software/templer/examples/complex/output/).

The generated "complex" example is the single best reference to the facilities and usage of the software, as it is intended as an introduction in its own right:

  *  [The reference site](http://www.steve.org.uk/Software/templer/examples/complex/output/).


Rebuilding a site
-----------------

If you're inside the directory containing your `templer.cfg` file simply
run `templer` with no arguments.  You may optionally add flags to control
what happens:

* `templer --verbose`
     * To see more details of what is happening.
* `templer --force`
     * To force a rebuild of the site.

In the general case `templer` should rebuild only the files which are needed
to be built, if you teak an include-file, or similar, it is possible you will
need to explicitly force a rebuild.


Plugins
-------

Templer allows itself to be extended via the addition of plugins, several
of which are distributed as part of the core code.

There are two types of plugins which are supported:

* Plugins which are used for formatting.
    * Converting input files from Textile, Markdown, etc, into HTML.

* Plugins which extend the variable definitions.
    * Creating variables that refer to file contents, file globs, etc.

There is a slightly different API for the two plugin-families, but both
are as simple as I could make them. The following plugins are included in the
distribution and may be studied for reference:

* Templer::Plugin::Markdown
   * Allows input files to be written in Markdown.
* Templer::Plugin::Perl
   * Allows dynamic Perl to be included in your input pages.
* Templer::Plugin::Textile
   * Allows input files to be written in Textile.
* Templer::Plugin::Breadcrumbs
   * Setup "breadcrumb" trails in your templates easily.
   * [Read the documentation](https://raw.github.com/skx/templer/master/lib/Templer/Plugin/Breadcrumbs.pm).
   * This was added partly as a demo, and partly for [use on my site](http://steve.org.uk/Software/templer/).
* Templer::Plugin::FileContents
   * Set variable values to the contents of files.
* Templer::Plugin::FileGlob
   * Set variable values to lists of files, based on a globbing pattern.
* Templer::Plugin::ShellCommand
   * Set variable values to the output of shell commands.




Formatter Plugins
------------------

The formatting plugins are intentionally simple because they are explicitly
enabled on a per-page basis.  There is no need to dynamically try them all in
turn, executing whichever matches a particular condition, for example.

A standard input page-file might look like this:

     Title: My page title.
     Format: textile
     ----
     This is a textile page.  It has **bold** text!

When this page is rendered the Textile plugin is created and it is then called
like so:

      if ( $plugin->available() )
      {
          $html = $plugin->format(  $input );
      }

If the named formatter is not present, or does not report itself as "enabled"
then the markup will be returned without any expansion.  To be explicit
any formatter plugin must implement only the following two methods:

* `available`
   * To determine whether this plugin is available.  (i.e. It might only be enabled if the modules it relies upon are present.)
* `format`
   * Given some input text return the rendered content.
   * This method receives all the per-page and global variables.



Variable Expansion Plugins
--------------------------

For the variable-expansion plugins the approach is similar, but an arbitrary
number of plugins may be registered and each one is executed in turn - so
return values are chained.

Each site page is loaded and the variable names & values are stored in a
hash.  Each plugin is free to modify that hash of known variables and
their values.

Generally we expect that plugins will look for variable values having
a particular pattern and ignoring those that don't match.  But there is
certainly no reason why you couldn't write a plugin to convert each
variable-value to uppercase, or perform other global operations.

In pseudo-code the processing looks like this:


        $data = ( "foo" => "bar",
                  title => "This is my page title .." );

        foreach my $plugin ( $plugins )
        {
             $data = $plugin->expand_variables( $page, $data );
        }


Each plugin will be called once, and once only, for each page.  The
`expand_variables` method is given a reference to the page from which the
variable(s) were loaded, which may be useful in some situations.

It should be noted for completeness that the same expansion happens on global
variables defined within your `templer.cfg` file.


Object Hierarchy
----------------

Although `templer` is distributed and used as a single script it is written
using a series of objects.  Bundling into a single binary allows for easier
distribution, installation and usage.

In brief the control flow goes like this:

* `templer` runs, parses the command line, etc.
* A `Templer::Global` object is created to read the `templer.cfg` file.
* A `Templer::Site` object is created, with a reference to the default options, and the previously created `Templer::Global` object.
* A `Templer::Timer` object is created to record the build-time.
* The build process is contained in `Templer::Site::build()`:
     * A `Templer::Plugin::Factory` object is created to load plugins.
     * A `Templer::Site::Page` object is created for each appropriate input.
     * Each page is output.
     * The plugins are unloaded.
* The assets are copied via `Templer::Site::copyAssets()`.
* The build-time/build-count is reported and the process is complete.



Problems
--------

Please report an issue via the github repository:

* https://github.com/skx/templer


Author
------

Steve Kemp <steve@steve.org.uk>
