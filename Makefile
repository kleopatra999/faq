index.html: always
	perl generate-web.pl .

always:

clean:
	rm index.html style.css
