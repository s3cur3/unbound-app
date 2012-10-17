ArchDirectoryObserver: Make FSEvents easier to use
============================================

The Mac's FSEvents framework is powerful stuff, but using it is too difficult.  It's C-based, complex, and painful.  There ought to be a better way.

Now there is.

ArchDirectoryObserver takes away the pain.  Observing a directory is now little more difficult than observing a key path--all you have to do is register to observe the directory's NSURL and implement a few methods.

Simple Example
-------------

Suppose you want to observe your app's template folder, and you already have a function that returns it:

    NSURL * MyTemplateFolderURL() {
        return [MyApplicationSupportDirectoryURL() URLByAppendingPathComponent:@"Templates" isDirectory:YES];
    }

To begin observing, add one of your objects as an observer of the directory:

    NSURL * templatesURL = MyTemplateFolderURL();
    [templatesURL addDirectoryObserver:self options:0 resumeToken:nil];

Then implement three methods:

    - (void)observedDirectory:(NSURL*)observedURL childrenAtURLDidChange:(NSURL*)changedURL historical:(BOOL)historical resumeToken:(ArchDirectoryObservationResumeToken)resumeToken {
        NSLog(@"Files in %@ have changed!", changedURL.path);
    }
    
    - (void)observedDirectory:(NSURL*)observedURL descendantsAtURLDidChange:(NSURL*)changedURL reason:(ArchDirectoryObserverDescendantReason)reason historical:(BOOL)historical resumeToken:(ArchDirectoryObservationResumeToken)resumeToken {
        NSLog(@"Descendents below %@ have changed!", changedURL.path);
    }
    
    - (void)observedDirectory:(NSURL*)observedURL ancestorAtURLDidChange:(NSURL*)changedURL historical:(BOOL)historical resumeToken:(ArchDirectoryObservationResumeToken)resumeToken {
        NSLog(@"%@, ancestor of your directory, has changed!", changedURL.path);
    }

When you're done observing, make sure you remove the observer:

    NSURL * templatesURL = MyTemplateFolderURL();
    [templatesURL removeDirectoryObserver:self];

Resume Tokens
-------------

ArchDirectoryObserver exposes the powerful FSEvents capability to observe changes that occurred in the past, when the app was not running.

This ability is used through the resumeToken: parameters to various methods.  Each observation is associated with a resume token; if you later register an observer with that resume token, observation will resume from the moment after that change.  That means you can save your last resume token to disk before quitting and then add the observer again with that resume token the next time you need it.  In so doing, you can learn about changes that happend when your app wasn't running.

Resume tokens can be written to a property list or an NSCoder archive, so they're easy to save.

Options
------

You can tweak the way ArchDirectoryObserver observes your directory with two options:

ArchDirectoryObserverObservesSelf: By default, you won't observe changes made by your own process.  Pass this parameter if you really do want to see them.

ArchDirectoryObserverResponsive: The default behavior does not notify you immediately of changes; it waits a few seconds and coalesces similar changes to avoid overwhelming your app with observations.  This kind of lag isn't very good where the user can see it, though.  This flag changes the coalescing algorithm to one that immediately notifies you of the first change and only coalesces subsequent changes.

Author
------

Written by Brent Royal-Gordon of Architechies <brent@architechies.com>

I'd love to hear from you if you've used this software.  Please also list my name and company and the name of the library wherever you give credit to similar contributions.  I consider these courtesies, however, not requirements.

Copyright
--------

This software is licensed under the MIT license:

Copyright (c) 2012 Architechies.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
