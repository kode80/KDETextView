# KDETextView
An OpenGL backed NSTextView replacement designed specifically for code editing.

Tired of fighting with NSTextView for years and still not finding any rock solid syntax highlighting/code completion frameworks, I've decided to finally bite the bullet and attempt a from-scratch replacement for NSTextView. 

The goal is to create a text view built from the ground up for code editing, that uses GPU rendering for performance and can simply be dropped into any project that needs a modern in-app code editor.

This project has a long way to go and I don't forsee it being production ready for a while but feel free to look around. :)

Currently uses [freetype-gl](https://github.com/rougier/freetype-gl) for text rendering.
