Instagram Unshredder
--------------------
This is a solution to the [Instagram Engineering Challenge](http://instagram-engineering.tumblr.com/post/12651721845/instagram-engineering-challenge-the-unshredder). It will automatically detect the width of the shredded strips before it unshreds an image.

I added a `Gemfile` and an `.rvmrc` file so you could isolate the gems it needs into its own rvm gemset (just in case you're nitpicky like me)


Usage
=====

Install the required libraries:

    bundle  # or just do: `gem install chunky_png` if you're not using rvm...
    
Now run it against one of the image files bundled with the project:

    ./unshred images/5.png

Now check the result:

    open images/5-unshredded.png
   

Caveats
=======
It relies on the [ChunkyPNG](https://github.com/wvanbergen/chunky_png) library to handle the low-level stuff that it needs to process the image file, so it is limited to PNG files only (but it also means you wont need to install any native code just to run it)
