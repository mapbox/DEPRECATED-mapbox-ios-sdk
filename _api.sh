#!/bin/bash

HTMLTOP='<div id="header">'
HTMLEND='<div class="main-navigation navigation-bottom">'
YAML="\
---
title: 0.3.0
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
  sed 's/class="title /class="/' | \
  sed 's/class="section /class="/' | \
  sed 's/ Class Reference<\/h1>/<\/h1>/' | \
  sed 's/ Protocol Reference<\/h1>/<\/h1>/'

