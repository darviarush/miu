
all: dist

link:
		rm -f /bin/miu /bin/rrrumiu
		ln -s $(realpath bin/miu) /bin/rrrumiu
		ln -s $(realpath bin/miu) /bin/miu

remote:
		git remote add origin git@bitbucket.org:darij/miu.git
		git remote add github git@github.com:darviarush/miu.git

README.md: miu/00-miu.miu.pl
		(cd miu && miu 00 && cp .miu/00-miu.markdown ../README.md)

dist: README.md
		git add .
		git commit
		git push origin master
		git push github master
		
clean:
	rm -r README.md miu/.miu/
