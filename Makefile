
all: dist

link:
		rm -f /bin/miu
		ln -s $(realpath bin/miu) /bin/miu


README.md: miu/00-miu.miu.pl
		(cd miu && miu 00 && cp .miu/00-miu.markdown ../README.md)

dist: README.md
		git add .
		git commit
		git push origin master
		git push github master
		
clean:
	rm -r README.md miu/.miu/
