This is source code to edit/generate documentation.

For the online HTML version please visit https://z00m128.github.io/sjasmplus/

(if you have full repository cloned on your local PC, you can open the [local html file](documentation.html) in your web browser)

Maintainer guide: [Integer argument parsing cookbook](getintarguments.md).

## Building and validating the documentation

The manual is maintained in [documentation.xml](documentation.xml), using DocBook XML.
The generated HTML is included in the repository; these tools are only needed when working on the documentation.

On Debian/Ubuntu, install the HTML build dependencies and XML validator:

```sh
sudo apt install docbook-xml docbook-xsl-ns xsltproc libxml2-utils
```

`docbook-xml` provides the DTD and XML catalog entries, `docbook-xsl-ns` provides the
stylesheets, `xsltproc` generates HTML, and `libxml2-utils` provides `xmllint` for validation.

From the repository root, validate the XML against its DocBook DTD, then generate HTML:

```sh
xmllint --nonet --noout --valid docs/documentation.xml
make docs
```

`make docs` updates [documentation.html](documentation.html), but does not perform DTD
validation. Run `xmllint` separately to catch invalid DocBook structure; `--nonet` uses
the locally installed DTD without network access.
