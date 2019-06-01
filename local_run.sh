docker run --rm --name blog -p 8000:4000 \
  --volume="/Users/hojinshim/source/stevenshim.github.io:/srv/jekyll" \
  -it jekyll/jekyll:3.8.5 \
  jekyll serve --watch --port 8000
