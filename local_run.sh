docker run --rm --name blog -p 4000:4000 \
  --volume="/Users/stevenshim/source/stevenshim.github.io:/srv/jekyll" \
  -it jekyll/jekyll:4.2.0 \
  jekyll serve
