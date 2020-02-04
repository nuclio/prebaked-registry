# Prebaked-registry
A docker-registry built with pre-baked nuclio onbuild processor images images in it

This pre-baked registry will contain the onbuild images consumed by nuclio for building processor images, 
so you can configure nuclio to consume it from a locally running registry using this image.
It's also a fully-functioning docker registry of course (so you can push images to it), notice it is NOT persistent

# Prerequisites:
- docker - installed and working
