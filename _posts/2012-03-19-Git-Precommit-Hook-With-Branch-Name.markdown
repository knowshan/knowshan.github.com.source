---
layout: post
title: Git pre-commit message hook for ticket numbered branches
categories: 
 git
---
** Git Hooks **

Git hooks are custom scripts that trigger upon certain git command.  The [ProGit](http://progit.org/book/ch7-3.html) book has explained Git hooks mechanism in detail so I recommend reading it before proceeding with following sections. 

** Prepare commit message **
 
In many projects a version control system (Git) is integrated with a project management software (trac). Most of the development activities or issues are tracked using 'ticket' system of the project management software and then actual coding activity is tracked or versioned using the version control system (VCS). The distributed VCS like Git make '[branching](http://gitref.org/branching/)' a lot easier than centralised VCS like Subversion which allows developers to switch contexts and keep different development activities isolated from each other. In fact it is a recommended practice to use 'branches' for tracking and sharing development activities. 

Often it is useful to name a 'branch' corresponding to a ticket number in the project management or issue tracking software rather than a descriptive name which might become confusing at some later stage. Also, it is a good practice to reference these ticket numbers  in the version control system's history (commit messages) so that tickets and corresponding development activity (code changes) can be cross-referenced easily. 

Follwing are two pre-commit hook examples which help in auto-populating the current working branch name (assumed to be ticket number) in the commit message template. 

*** Sed ***
{% highlight bash %} 
  msg=`git branch | sed -e '/^[^*]/d' -e 's/* \(.*\)/# Commit for [galaxy:ticket:\1]/'`
  sed -i -e "1i $msg" "$1"
{% endhighlight %}

The above example uses GNU sed and hence it doesn't work on the Mac OS which uses BSD sed.

*** Ruby ***

Below is a Ruby one-liner example that works on any system with a Ruby interperter (tested with Matz MRI 1.8.7). 
{% highlight ruby %}
  ruby  -i -pe 'puts `git branch`.split(/\n/).select {|e| e =~ /\*.*/}.to_s.sub(/\* /,"# Commit for [galaxy:ticket:").concat("]") if $.==1' "$1"
{% endhighlight %}

These examples will need to modified according to your ticket-branch naming conventions and other syntax requirements of your project or issue tracking software.
