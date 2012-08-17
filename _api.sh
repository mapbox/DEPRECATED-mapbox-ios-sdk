#!/bin/bash

HTMLTOP='<div id="header">'
HTMLEND='<div class="main-navigation navigation-bottom">'
YAML="\
---
title: iOS SDK 0.3.0
layout: api
permalink: /api
categories: api
navigation:"
CONTENT=""

scrape() {
  FR=`grep -n "$HTMLTOP" $1 | grep -o [0-9]*`
  TO=`grep -n "$HTMLEND" $1 | grep -o [0-9]*`
  LINES=`echo "$TO - $FR" | bc`
  echo "$(tail -n +$FR $1 | head -n $LINES)"
}

YAML="$YAML\n  Classes:"
for file in `find docset -wholename "*Classes/*.html" | sort`; do
  YAML="$YAML\n  - $(basename $file .html)"
  CONTENT="$CONTENT\n$(scrape $file)"
done

YAML="$YAML\n  Protocols:"
for file in `find docset -wholename "*Protocols/*.html" | sort`; do
  YAML="$YAML\n  - $(basename $file .html)"
  CONTENT="$CONTENT\n$(scrape $file)"
done

echo -e "$YAML"
echo "---"
echo -e "$CONTENT" | \
  sed 's,class="title ,class=",' | \
  sed 's,class="section ,class=",' | \
  sed 's, Class Reference</h1>,</h1>,' | \
  sed 's, Protocol Reference</h1>,</h1>,' | \
  # Add an id to h1s so they can be looked up by anchor links.
  sed 's,<h1 class="title-header">\([^<]*\)</h1>,<h1 class="title-header" id="\L\1">\E\1</h1>,' | \
  # Replace links to class/protocol pages with anchor links. Avoids http:// urls.
  sed 's,<a href="[^#][^:\"]*">\([^<]*\)</a>,<a href="#\L\1">\E\1</a>,g'
