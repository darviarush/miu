
all: dist

link:
		rm -f /bin/miu /bin/rrrumiu
		ln -s $(realpath bin/miu) /bin/rrrumiu
		ln -s $(realpath bin/miu) /bin/miu

remote:
		git remote add origin git@bitbucket.org:darij/miu.git;	git remote add github git@github.com:darviarush/miu.git

dist: test cpan
		git add .
		git commit
		git push origin master
		git push github master
		
clean:
		rm -r README.md t mark .miu

test:
		miu 00:10
		
pl:
		miu 00
		
js:
		miu 10

		
cpan:
		perl gencpanfile.pl > cpanfile
