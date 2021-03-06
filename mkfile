MKSHELL=/usr/local/plan9/bin/rc
MARKDOWNOPTS="-html5 -squash"

all:Q: html repository static
	echo Built website

html:V: header footer repository wiki blog
	for(dir in `{find src -type d}) mkdir -p `{ echo $dir | sed 's/src/site/'}
	for(md in `{find src -name '*.md'})\
	outputhtml=`{echo $md | sed -e 's/src/site/' -e 's/.md/.html/'}{\
	mkdir -pv `{dirname $outputhtml} ; \
	TITLE=`{basename $md | cut -d . -f 1} sh ./header; \
	markdown $md; \
	sh ./footer} > $outputhtml

static: html
	for(file in `{find src -type f}){
	if ( echo $file | grep -q '.md' ) true
	if not cp $file `{echo $file | sed 's/src/site/'}}

header:
	cat `{find templates -name '*.header' | sort } > \
		header
	chmod +x header

footer:
	cat `{find templates -name '*.footer' | sort } > \
		footer
	chmod +x footer

repository:V:
	sh -c 'scripts/gen-db ./src'

blog:V:
	sh -c 'scripts/gen-blog ./blog ./src'

wiki:V:
	git clone --quiet git://git.carbslinux.org/wiki /tmp/wiki
	for(md in `{find /tmp/wiki/wiki -name '*.md' ! -name 'index.md' }){
	printf '\n### Git Commit Information\n\n' >> $md
	GIT_DIR=/tmp/wiki/.git git -C /tmp/wiki log -- $md | grep Date | sed 's/Date:/* **Last Edit:**/;1q' >> $md
	printf '* **Commit Message**: ' >> $md
	GIT_DIR=/tmp/wiki/.git git -C /tmp/wiki log -1 '--pretty=%B' -- $md | awk 'NF' >> $md
	GIT_DIR=/tmp/wiki/.git git -C /tmp/wiki log -- $md | grep Author | sed 's/Author:/* **Author:**/;1q' >> $md
	relapath=`{GIT_DIR=/tmp/wiki/.git git -C /tmp/wiki ls-files $md}
	printf '* **[View Source](https://carbslinux.org/git/wiki/file/%s.html)**\n' $relapath >> $md
	}
	mv /tmp/wiki/wiki src/wiki
	rm -rf /tmp/wiki
	sh -c 'scripts/gen-wiki-index'

clean:V:
	rm -rf site footer header src/blog src/rss.xml \
	src/packages src/wiki site.tar.gz \
		website-master.tar.gz

dist:V: clean
	mkdir website-master
	cp -R README mkfile blog scripts src templates \
		website-master
	tar -cf website-master.tar website-master
	gzip website-master.tar
	rm -rf website-master

pkg:QV: clean all
	tar -cf site.tar site
	gzip site.tar

install:V: all
	[ $#DESTDIR -eq 1 ]
	mkdir -p $DESTDIR
	cp -r site $DESTDIR

uninstall:V:
	[ $#DESTDIR -eq 1 ]
	rm -rf $DESTDIR/site
