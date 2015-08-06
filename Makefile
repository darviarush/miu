PWD = `pwd`

all: dist

link:
		rm /bin/miu
		ln -s "$(PWD)/bin/miu" /bin/miu


README.md: miu/00-miu.miu.pl
		(cd miu && miu 00 && cp .miu/00-miu.markdown ../README.md)

dist: README.md
		git push origin master
